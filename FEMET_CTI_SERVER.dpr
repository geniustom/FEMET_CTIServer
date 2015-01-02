program FEMET_CTI_SERVER;
{$APPTYPE CONSOLE}
uses
  sharemem,
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  ScktComp,
  Forms,
  Dialogs,
  ServerForm in 'ServerForm.pas' {ConfigFrom},
  MainAp in 'MainAp.pas',
  ConsoleCommand in 'ConsoleCommand.pas',
  CheckDB in 'CheckDB.pas',
  ProcessQueue in 'ProcessQueue.pas',
  CheckData_Lib in 'CheckData_Lib.pas',
  MiddleLib in 'MiddleLib.pas',
  CTI_DataType in 'CTI_DataType.pas';

{$R *.res}

var
   start:TRun;
   Msg:TMsg;
begin
  ConsoleCommand.DataPath:=ExtractFilePath(Application.ExeName);
  start:=TRun.Create;
  start.main;
end.
