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
  if NowIsClosing=true then exit;      //�קK�ۦP������P�ɰ��榹���
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
  LOG(0,'�t���ܼƪ�l��',LightYellow);
//============================================================
  time:= windows.GetTickCount- time;
  LOG(5,'System:�t���ܼƪ�l�Ƨ���,�Ӯ�:'+inttostr(time)+' ms',Lightwhite);
//===========================================================CTI DB �}��
  try
    LOG(0,'���J�~���Ȼs�ƨ禡�w',LightYellow);
    LIB_TargetDBIsOK(true);

    LOG(0,'���J�t�ΰ����',Lightred);
    LOG(5,'System:���J�iCTI DB�˴�������j',Lightwhite);
    DBThread:=TCheckDB.Create(true);
    DBThread.Resume;

    LOG(5,'System:���J�iTARGET DB�˴�������j',Lightwhite);
    MidLibCHKThread:=TMidLibCHKDB.Create(true);
    MidLibCHKThread.Resume;

    LOG(5,'System:���J�iCTI DB��e������j',Lightwhite);
    ProcessQueueThread:=TProcessQueue.Create(true);
    ProcessQueueThread.Resume;

    LOG(5,'System:���J�iTARGET DB��e������j',Lightwhite);
    MidLibTransThread:=TMidLibTrans.Create(true);
    MidLibTransThread.Resume;

    LOG(5,'System:���J�i�ʱ�������j',Lightwhite);
    ReportThread:=TLogReport.Create(true);
    ReportThread.Resume;
  except
    Err_flag:=1;
  end;
  sleep(1000);
//===========================================================�i�J�u�@�Ҧ�
  if Err_flag=0 then
    LOG(0,'���A���]�w����,�i�J�u�@�Ҧ�',LightYellow);

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
      LOG(0,'�D�{���˴���i�ʱ�������j���`..�{�b�N����..',LightYellow);
      self.ForceRestart();
    end;
    ReportThread.IamAlive:=false;
    SystemCheckTime:=windows.GetTickCount;
  end;
end;

end.
