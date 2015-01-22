unit CheckDB;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,inifiles,
  ExtCtrls,DB, ADODB,{DBAccess,}ShellAPI;

type
  TCheckDB = class(TThread)
  public
    DBIsOK:boolean;
    DBWasOK:boolean;
    IamAlive:boolean;
    ISBusy:boolean;

    TEST_CTI: TADOConnection;
    TEST_Query: TADOQuery;
    
    //procedure InitialDB();
    procedure Execute; override;
  end;

  TMidLibCHKDB = class(TThread)
  public
    DBIsOK:boolean;
    DBWasOK:boolean;
    IamAlive:boolean;
    ISBusy:boolean;
    procedure Execute; override;
  end;

var
DBThread:TCheckDB;
MidLibCHKThread:TMidLibCHKDB;

function LIB_TargetDBIsOK(ShowLogToScreen:boolean):boolean;stdcall;far; external 'MiddleLib\MiddleLib.dll';

implementation
uses ConsoleCommand,ServerForm,ProcessQueue;


procedure TCheckDB.Execute;
begin
  self.Priority:= tpLower;
  DBWasOK:=true;
  while true do
  begin
    self.IamAlive:=true;
    self.ISBusy:=true;
    DBIsOK:=true;
    try
      InitialCTIDB(TEST_CTI,false);
      if TEST_Query<>nil then
      begin
        TEST_Query.close;
        TEST_Query.Free;
      end;
      TEST_Query:=TADOQuery.Create(nil);
      TEST_Query.Connection:=TEST_CTI;
      TEST_Query.SQL.Text:='select Top 1 * from Gateway_Data_Pack';
      TEST_Query.Open;
    except
      DBIsOK:=false;
    end;
    self.ISBusy:=false;

    if DBIsOK=false then
    begin
      ReportToFile(DataPath,formatDatetime('YYYY/MM/DD HH:NN:SS：',now)+'CTI DB Error');
      LOG(5,'TargetDB:重新進行連線測試',LightGreen);
    end
    else
    begin
      ReportToFile(DataPath,formatDatetime('YYYY/MM/DD HH:NN:SS：',now)+'CTI DB OK');
      if DBWasOK=false then
      begin
        ConfigFrom.ForceRestart();
      end;
    end;
    DBWasOK:=DBIsOK;
    application.ProcessMessages;
    sleep(5000);
  end;
end;


procedure TMidLibCHKDB.Execute;
begin
  self.Priority:= tpLower;
  DBWasOK:=true;
  while true do
  begin
    self.IamAlive:=true;
    self.ISBusy:=true;
    try
      DBIsOK:=LIB_TargetDBIsOK(false);
    except
      DBIsOK:=false;
    end;
    self.ISBusy:=false;

    if DBIsOK=false then
    begin
      ReportToFile(DataPath,formatDatetime('YYYY/MM/DD HH:NN:SS：',now)+'TARGET DB Error');
      LOG(5,'TargetDB:重新進行連線測試',LightGreen);
    end
    else
    begin
      ReportToFile(DataPath,formatDatetime('YYYY/MM/DD HH:NN:SS：',now)+'TARGET DB OK');
      if DBWasOK=false then
      begin
        ConfigFrom.ForceRestart();
      end;
    end;
    DBWasOK:=DBIsOK;
    application.ProcessMessages;
    sleep(5000);
  end;
end;



end.









{
procedure TCheckDB.InitialDB();
var
  C_SVR,C_USN,C_PWD,C_CAT:string;
  C_Port:integer;
  FileName:string;
  ConfigINI:Tinifile;
begin
  ConfigINI:=tinifile.create(DataPath+'Config.ini');
//===========================================================CTI DB
  C_SVR          := ConfigINI.ReadString('CTISQL','IP','192.168.0.244');
  C_USN          := ConfigINI.ReadString('CTISQL','ID','sa');
  C_PWD          := ConfigINI.ReadString('CTISQL','PWD','0000');
  C_CAT          := ConfigINI.ReadString('CTISQL','CAT','CallCenter');
//===========================================================CTI DB 開啟
  if TEST_CTI<>nil then
  begin
    TEST_CTI.close;
    TEST_CTI.Free;
  end;

  TEST_CTI:=TADOConnection.Create(nil);
  TEST_CTI.CommandTimeout:=5;
  TEST_CTI.ConnectionString:='Provider=SQLOLEDB.1;Persist Security Info=True;Initial Catalog='+C_CAT+';';
  TEST_CTI.ConnectionString:=TEST_CTI.ConnectionString+'Data Source='+C_SVR+';User ID='+C_USN+';Password='+C_PWD+';';

  if TEST_Query<>nil then
  begin
    TEST_Query.close;
    TEST_Query.Free;
  end;

  TEST_Query:=TADOQuery.Create(nil);
  TEST_Query.Connection:=TEST_CTI;
  TEST_Query.SQL.Text:='select Top 1 * from Gateway_Data_Pack';
end;
}
