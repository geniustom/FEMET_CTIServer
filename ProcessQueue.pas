unit ProcessQueue;

interface


uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,DB, ADODB,inifiles;

type
  TProcessQueue = class(TThread)
  public
    DBIsOK:boolean;
    IamAlive:boolean;
    CTI_SQL: TADOConnection;
    CTIQuery: TADOQuery;
    DataQuery:TADOQuery;
    procedure Execute; override;
  end;

  TLogReport = class(TThread)
  public
    IamAlive:boolean;
    procedure Execute; override;
  end;  


var
  ProcessQueueThread:TProcessQueue;
  ReportThread:TLogReport;

  procedure InitialCTIDB(var CONNSQL:TADOConnection;ShowLog:boolean);

implementation

uses ConsoleCommand,ServerForm,CheckDB,CheckData_Lib,MiddleLib;



procedure InitialCTIDB(var CONNSQL:TADOConnection;ShowLog:boolean);
var
  C_SVR,C_USN,C_PWD,C_SID,C_CAT:string;
  C_Port:integer;
  ConfigINI:Tinifile;
  time:integer;
  Err_flag:integer;
begin
  if CONNSQL<>nil then
  begin
    CONNSQL.close;
    CONNSQL.Free;
  end;

  CONNSQL:=TADOConnection.Create(nil);
  CONNSQL.ConnectionTimeout:=5;
  CONNSQL.CommandTimeout:=5;

  ConfigINI:=tinifile.create(DataPath+'Config.ini');
//===========================================================CTI DB
  C_SVR          := ConfigINI.ReadString('CTISQL','IP','192.168.0.244');
  C_USN          := ConfigINI.ReadString('CTISQL','ID','sa');
  C_PWD          := ConfigINI.ReadString('CTISQL','PWD','0000');
  C_CAT          := ConfigINI.ReadString('CTISQL','CAT','CallCenter');

  ConfigINI.WriteString('CTISQL','IP',C_SVR);
  ConfigINI.WriteString('CTISQL','ID',C_USN);
  ConfigINI.WriteString('CTISQL','PWD',C_PWD);
  ConfigINI.WriteString('CTISQL','CAT',C_CAT);
//===========================================================CTI DB 開啟
  try
    if ShowLog then LOG(0,'載入MS SQL驅動程式',LightYellow);
    if ShowLog then LOG(5,'CTIDB:IP='+C_SVR+' ID='+C_USN+' PWD='+C_PWD+' CAT='+C_CAT,Lightcyan);
    if ShowLog then LOG(5,'CTIDB:DB連線中',Lightcyan);

    time:=windows.GetTickCount;
    CONNSQL.Close;
    CONNSQL.ConnectionString:='Provider=SQLOLEDB.1;Persist Security Info=True;';
    CONNSQL.ConnectionString:=CONNSQL.ConnectionString+'Initial Catalog='+C_CAT+';Data Source='+C_SVR+';User ID='+C_USN+';Password='+C_PWD+';';
    CONNSQL.Open;
  except
    if ShowLog then LOG(5,'CTIDB:DB連線失敗',Lightcyan);
    Err_flag:=1;
  end;
//===========================================================進入工作模式
  if Err_flag<>1 then
  begin
    time:= windows.GetTickCount- time;
    if ShowLog then LOG(5,'CTIDB:SQL Server連線完成,耗時:'+inttostr(time)+' ms',Lightcyan);
  end;
end;

procedure TProcessQueue.Execute;
var
  index:integer;
  DID:integer;
  ProcessTime:integer;
  DataList:Tstringlist;
  ErrFlag:boolean;
begin
  self.Priority:= tpLowest;
  DataList:=Tstringlist.Create;
  InitialCTIDB(CTI_SQL,true);
  //======================================================
  while true do
  begin
    ErrFlag:=false;
    self.IamAlive:=true;
    ProcessTime:= windows.GetTickCount;
    try
      InitialCTIDB(CTI_SQL,false);
      CTIQuery:=TADOQuery.Create(nil);
      CTIQuery.Connection:=CTI_SQL;
      DataQuery:=TADOQuery.Create(nil);
      DataQuery.Connection:=CTI_SQL;
      CTIQuery.SQL.Text:='SELECT * FROM Gateway_Data_Pack';
      //'Select top 1 Serial_No from Gateway_Data_Pack order by Serial_No';
      CTIQuery.Open;
    except
      ErrFlag:=true;
    end;

    if ErrFlag=false then
    begin
      if CTIQuery.RecordCount>0 then
      begin
        LOG(0,'CTIDB:備援資料庫尚有' + inttostr(CTIQuery.RecordCount) + '筆通訊資料未分析',LightYellow);
        LOG(6,'------------------------------------------------------------------------',Darkcyan);
        index:=0;
        CTIQuery.SQL.Text:= 'Select top 1 * from Gateway_Data_Pack order by Serial_No';     //因為用WHILE，所以只取一筆就好
        CTIQuery.Open;

        while CTIQuery.RecordCount>0 do
        begin
          self.IamAlive:=true;
          DataList.Clear;
          DataList.Delimiter:=',';
          //=======================================
          DataList.Add(CTIQuery.Fields.FieldByName('CallerID').AsString);
          DataList.DelimitedText:=DataList.DelimitedText+','+CTIQuery.Fields.FieldByName('DTMF_Code').AsString;
          DID:=CTIQuery.Fields.FieldByName('Serial_No').AsInteger;

          index:=index+1;
          StrToDB(DataQuery,index,ProcessPacket(DataList.DelimitedText));
          //=======================================
          CTIQuery.Delete;
          CTIQuery.Close;
          CTIQuery.SQL.Text:= 'Select top 1 * from Gateway_Data_Pack order by Serial_No';     //因為用WHILE，所以只取一筆就好
          CTIQuery.Open;
          application.ProcessMessages;
        end;

        CTIQuery.Close;
        ProcessTime:= windows.GetTickCount-ProcessTime;
        LOG(5,'CTIDB:訊息備援資料分析完成,耗時:'+inttostr(ProcessTime)+' ms',LightYellow);
        LOG(6,'==============================================================================',DarkPurb);
      end;
    end;
//====================================================
  sleep(1000);
  end;
end;



procedure TLogReport.Execute;
var
 Interval,i:integer;
 ConfigINI:Tinifile;
 CheckAllThread:integer;
begin
  self.Priority:= tpLower;
  ConfigINI:=tinifile.create(DataPath+'Config.ini');
  Interval:= ConfigINI.ReadInteger('REPORT','Interval',10);
  ConfigINI.WriteInteger('REPORT','Interval',Interval);

  while true do
  begin
    ReportToFile(DataPath,formatDatetime('YYYY/MM/DD HH:NN:SS：',now)+'Report');

    for i:=0 to Interval-1 do
    begin
      application.ProcessMessages;
      self.IamAlive:=true;
      sleep(1000);
    end;
//===========================================
    if DBThread.IamAlive=false then
    begin
        LOG(0,'監控程式檢測到【CTI DB檢測執行緒】沒有回應..自我修復中..',LightYellow);
        ConfigFrom.ForceRestart();
    end;
    if MidLibCHKThread.IamAlive=false then
    begin
      LOG(0,'監控程式檢測到【TARGET DB檢測執行緒】沒有回應..自我修復中..',LightYellow);
      ConfigFrom.ForceRestart();
    end;

//===========================================

    if (ProcessQueueThread.IamAlive=false) then
    begin
      LOG(0,'監控程式檢測到【CTI DB轉送執行緒】沒有回應..自我修復中..',LightYellow);
      ConfigFrom.ForceRestart();
    end;
    if (MidLibTransThread.IamAlive=false) then
    begin
      LOG(0,'監控程式檢測到【TARGET DB轉送執行緒】沒有回應..自我修復中..',LightYellow);
      ConfigFrom.ForceRestart();
    end;

//===========================================
    if MidLibCHKThread<>nil then MidLibCHKThread.IamAlive:=false;
    if MidLibTransThread<>nil then MidLibTransThread.IamAlive:=false;
    if DBThread<>nil then DBThread.IamAlive:=false;
    if ProcessQueueThread<>nil then ProcessQueueThread.IamAlive:=false;
    self.IamAlive:=true;
  end;
end;

end.
