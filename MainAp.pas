unit MainAP;

interface
uses  forms,Dialogs,inifiles,Windows,Messages, SysUtils,Variants, Classes, ScktComp,ConsoleCommand;

type

  TRun = class(TObject)
  private
  public
     procedure main;
  end;

implementation
uses ServerForm;//,unit1,MenuForm;



procedure TRun.main();
var
   Msg:TMsg;
   i:integer;
   time:int64;
   HWND:integer;
   MyHWND:integer;
begin
  
  HWND:=findwindow(nil,'Server4DB');
  while HWND<>0 do
  begin
    //ExtractFileName(Application.ExeName)
    //WinExec(pchar('taskkill /f /t /pid '+inttostr(HWND)),0);
    PostMessage(HWND,WM_CLOSE,0,0);
    sleep(100);
    application.ProcessMessages;
    HWND:=findwindow(nil,'Server4DB');
  end;
  sleep(1000);
//=============================================
  writeln('');
  writeln('');
  LOG(6,'                         Server程式初始化中..請稍候',LightGreen);
  writeln('');
  LOG(6,'                                【載入進度】',LightGreen);
  writeln('');
  for i:=0 to 38 do
  begin
    write('█');
    sleep(30);
  end;
  writeln('');
  writeln('');

//=============================================
  Application.Initialize;
  Application.CreateForm(TConfigFrom, ConfigFrom);
  Application.Run;
end;


end.
