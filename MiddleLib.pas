unit MiddleLib;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,inifiles,ConsoleCommand,CTI_DataType,
  ExtCtrls,DB, ADODB,DBAccess;

type

  TMidLibTrans = class(TThread)
  public
    IamAlive:boolean;
    ISBusy:boolean;
    CTI_SQL: TADOConnection;
    ProcessQuery:TADOQuery;
    ErrorQuery:TADOQuery;
    procedure Execute; override;
    function DBToData(var ADO:TADOQuery):TCTIData;
    procedure DataToDB(var CTIData:TCTIData;var ADO_OK:TADOQuery;var ADO_ERR:TADOQuery);
  end;


function LIB_TransferData(var CTI_Data:TCTIData):boolean;stdcall;far; external 'MiddleLib\MiddleLib.dll';


var
  MidLibTransThread:TMidLibTrans;

implementation
uses ServerForm,ProcessQueue;



procedure TMidLibTrans.Execute;
var
   MidLibData:TCTIData;
   DataCount:integer;
   ProcessTime:integer;
   ErrFlag:boolean;
begin
  self.Priority:= tpLower;
  while true do
  begin
     ErrFlag:=false;
     self.IamAlive:=true;
     try
        InitialCTIDB(CTI_SQL,false);
        if ErrorQuery<>nil then
        begin
          ErrorQuery.close;
          ErrorQuery.Free;
        end;
        ErrorQuery:=TADOQuery.Create(nil);
        ErrorQuery.Connection:=CTI_SQL;
        
        if ProcessQuery<>nil then
        begin
          ProcessQuery.close;
          ProcessQuery.Free;
        end;
        ProcessQuery:=TADOQuery.Create(nil);
        ProcessQuery.Connection:=CTI_SQL;
        ProcessQuery.SQL.Text:='select * from Gateway_Data_Process where Process=0';
        ProcessQuery.Open;
     except
        ErrFlag:=true;
     end;

     if ErrFlag=false then
     begin
      DataCount:=0;
      if ProcessQuery.RecordCount>0 then
      begin
        LOG(0,'QUEUE:目前尚有'+inttostr(ProcessQuery.RecordCount)+'筆資料未處理,呼叫外部函式庫處理中..',LightPurb);
        LOG(6,'------------------------------------------------------------------------',DarkWhite);
        ProcessQuery.close;
        ProcessQuery.SQL.Text:='select Top 1 * from Gateway_Data_Process where Process=0 order by Serial_No';
        ProcessQuery.Open;

        while ProcessQuery.RecordCount>0 do
        begin
           self.IamAlive:=true;
           ProcessTime:=windows.GetTickCount;
           DataCount:=DataCount+1;
           LOG(5,'QUEUE:第 '+inttostr(DataCount)+' 筆資料轉送中...',lightpurb);

           MidLibData:=DBToData(ProcessQuery);
           if LIB_TransferData(MidLibData)=true then
              DataToDB(MidLibData,ProcessQuery,ErrorQuery);
           
           ProcessTime:=windows.GetTickCount-ProcessTime;
           LOG(5,'QUEUE:處理資料共耗時: '+inttostr(ProcessTime)+' ms',lightpurb);
           LOG(6,'------------------------------------------------------------------------',DarkWhite);
           ProcessQuery.SQL.Text:='select Top 1 * from Gateway_Data_Process where Process=0 order by Serial_No';
           ProcessQuery.Open;
        end;
        LOG(5,'QUEUE:資料轉介完成',lightpurb);
      end;
     end;

    application.ProcessMessages;
    sleep(1000);
  end;
end;











procedure TMidLibTrans.DataToDB(var CTIData:TCTIData;var ADO_OK:TADOQuery;var ADO_ERR:TADOQuery);
var DBTime:integer;
begin
  DBTime:=windows.GetTickCount;
  if CTIData.Process=1 then   //處理完成..更新DB
  begin
    ADO_OK.SQL.Text:='select * from Gateway_Data_Process where Serial_No='+inttostr(CTIData.Serial_No);
    ADO_OK.Open;
    ADO_OK.Edit;
    //ADO_OK.FieldByName('Serial_No').AsInteger       :=CTIData.Serial_No;
    ADO_OK.FieldByName('CallerID').AsString           :=CTIData.CallerID;
    ADO_OK.FieldByName('DTMF_Code').AsString          :=CTIData.DTMF_Code;
    ADO_OK.FieldByName('Process').Asinteger           :=CTIData.Process;
    ADO_OK.FieldByName('ProcessMessage').AsString     :=CTIData.ProcessMessage;
    ADO_OK.FieldByName('Date_Save').AsDateTime        :=CTIData.Date_Save;
    ADO_OK.FieldByName('Date_Process').AsDateTime     :=CTIData.Date_Process;
    //ADO_OK.FieldByName('Date_Send').AsDateTime      :=CTIData.Date_Send;
    ADO_OK.FieldByName('MSG_GWID').AsString           :=CTIData.MSG_GWID;
    ADO_OK.FieldByName('MSG_DATA').AsString           :=CTIData.MSG_DATA;
    ADO_OK.FieldByName('MSG_ButtonSite').AsString     :=CTIData.MSG_ButtonSite;
    ADO_OK.FieldByName('MSG_MSGType').AsString        :=CTIData.MSG_MSGType;
    ADO_OK.FieldByName('MSG_MSGText').AsString        :=CTIData.MSG_MSGText;
    ADO_OK.FieldByName('MSG_GWTime').AsDateTime       :=CTIData.MSG_GWTime;
    ADO_OK.FieldByName('Return_Serial_no').AsInteger  :=CTIData.Return_Serial_No;
    ADO_OK.Post;
    ADO_OK.Close;
    DBTime:=windows.GetTickCount-DBTime;

    LOG(5,'QUEUE:資料轉送完成,更改Process=1,耗時:'+inttostr(DBTime)+'ms',lightpurb);
  end
  else
  begin
    try
      ADO_OK.SQL.Text:='select * from Gateway_Data_Process where Serial_No='+inttostr(CTIData.Serial_No);
      ADO_OK.Open;
      ADO_ERR.SQL.Text:='select top1 * from Gateway_Data_Error';
      ADO_ERR.Open;
      ADO_ERR.Append;

      //ADO_ERR.FieldByName('Serial_No').AsInteger     :=CTIData.Serial_No;
      ADO_ERR.FieldByName('CallerID').AsString          :=CTIData.CallerID;
      ADO_ERR.FieldByName('DTMF_Code').AsString         :=CTIData.DTMF_Code;
      ADO_ERR.FieldByName('Process').Asinteger          :=CTIData.Process;
      ADO_ERR.FieldByName('ProcessMessage').AsString    :=CTIData.ProcessMessage;
      ADO_ERR.FieldByName('Date_Save').AsDateTime       :=CTIData.Date_Save;
      ADO_ERR.FieldByName('Date_Process').AsDateTime    :=CTIData.Date_Process;
      //ADO_ERR.FieldByName('Date_Send').AsDateTime    :=CTIData.Date_Send;
      ADO_ERR.FieldByName('MSG_GWID').AsString          :=CTIData.MSG_GWID;
      ADO_ERR.FieldByName('MSG_DATA').AsString          :=CTIData.MSG_DATA;
      ADO_ERR.FieldByName('MSG_ButtonSite').AsString    :=CTIData.MSG_ButtonSite;
      ADO_ERR.FieldByName('MSG_MSGType').AsString       :=CTIData.MSG_MSGType;
      ADO_ERR.FieldByName('MSG_MSGText').AsString       :=CTIData.MSG_MSGText;
      ADO_ERR.FieldByName('MSG_GWTime').AsDateTime      :=CTIData.MSG_GWTime;
      ADO_ERR.Post;
      ADO_ERR.Close;
    finally
      ADO_OK.Delete;
      DBTime:=windows.GetTickCount-DBTime;
      LOG(5,'QUEUE:資料轉送有誤,移至Gateway_Data_Error,耗時:'+inttostr(DBTime)+'ms',lightpurb);
    end;
  end;
end;


function TMidLibTrans.DBToData(var ADO:TADOQuery):TCTIData;
begin
    result.Serial_No         :=ADO.FieldByName('Serial_No').AsInteger;
    result.CallerID          :=ADO.FieldByName('CallerID').AsString;
    result.DTMF_Code         :=ADO.FieldByName('DTMF_Code').AsString;
    result.Process           :=ADO.FieldByName('Process').Asinteger;
    result.ProcessMessage    :=ADO.FieldByName('ProcessMessage').AsString;
    result.Date_Save	       :=ADO.FieldByName('Date_Save').AsDateTime;
    result.Date_Process	     :=ADO.FieldByName('Date_Process').AsDateTime;
    result.Date_Send	       :=ADO.FieldByName('Date_Send').AsDateTime;
    result.MSG_GWID          :=ADO.FieldByName('MSG_GWID').AsString;
    result.MSG_DATA          :=ADO.FieldByName('MSG_DATA').AsString;
    result.MSG_ButtonSite    :=ADO.FieldByName('MSG_ButtonSite').AsString;
    result.MSG_MSGType       :=ADO.FieldByName('MSG_MSGType').AsString;
    result.MSG_MSGText       :=ADO.FieldByName('MSG_MSGText').AsString;
    result.MSG_GWTime        :=ADO.FieldByName('MSG_GWTime').AsDateTime;
    result.Return_Serial_No  :=0;
end;



end.
