unit ServerForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ADODB,inifiles,ConsoleCommand,MiddleLib, ExtCtrls;

type
  TConfigFrom = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
      SystemCheckTime:int64;
      NowIsClosing:boolean;
      procedure ForceRestart();
  end;

var
  ConfigFrom: TConfigFrom;


  
implementation
uses CheckDB,ProcessQueue;

{$R *.dfm}
procedure TConfigFrom.ForceRestart();
begin
  if NowIsClosing=true then exit;      //避免相同執行緒同時執行此函數
  NowIsClosing:=true;
  WinExec(pchar(Application.ExeName),0);
  self.Close;
end;


procedure TConfigFrom.FormCreate(Sender: TObject);
var
  Err_flag:integer;
  time:int64;
begin
  self.Caption:='Server4DB';

  time:=windows.GetTickCount;
  Err_flag:=0;

//===========================================================
  LOG(0,'系統變數初始化',LightYellow);
//============================================================
  time:= windows.GetTickCount- time;
  LOG(5,'System:系統變數初始化完成,耗時:'+inttostr(time)+' ms',Lightwhite);
//===========================================================CTI DB 開啟
  try
    LOG(0,'載入外部客製化函式庫',LightYellow);
    LIB_TargetDBIsOK(true);

    LOG(0,'載入系統執行緒',Lightred);
    LOG(5,'System:載入【CTI DB檢測執行緒】',Lightwhite);
    DBThread:=TCheckDB.Create(true);
    DBThread.Resume;

    LOG(5,'System:載入【TARGET DB檢測執行緒】',Lightwhite);
    MidLibCHKThread:=TMidLibCHKDB.Create(true);
    MidLibCHKThread.Resume;

    LOG(5,'System:載入【CTI DB轉送執行緒】',Lightwhite);
    ProcessQueueThread:=TProcessQueue.Create(true);
    ProcessQueueThread.Resume;

    LOG(5,'System:載入【TARGET DB轉送執行緒】',Lightwhite);
    MidLibTransThread:=TMidLibTrans.Create(true);
    MidLibTransThread.Resume;

    LOG(5,'System:載入【監控執行緒】',Lightwhite);
    ReportThread:=TLogReport.Create(true);
    ReportThread.Resume;
  except
    Err_flag:=1;
  end;
  sleep(1000);
//===========================================================進入工作模式
  if Err_flag=0 then
    LOG(0,'伺服器設定完成,進入工作模式',LightYellow);

//===========================================
  SystemCheckTime:=windows.GetTickCount;
  Timer1.Enabled:=true;
end;

procedure TConfigFrom.Timer1Timer(Sender: TObject);
begin
  if (windows.GetTickCount-SystemCheckTime)>5000 then
  begin
    application.ProcessMessages;
    if ReportThread.IamAlive=false then
    begin
      LOG(0,'主程式檢測到【監控執行緒】異常..現在將重啟..',LightYellow);
      self.ForceRestart();
    end;
    ReportThread.IamAlive:=false;
    SystemCheckTime:=windows.GetTickCount;
  end;
end;

end.
