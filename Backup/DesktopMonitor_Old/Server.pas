unit Server;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, MemDS, DBAccess, Ora,IdMessage, IdTCPConnection, IdTCPClient,
  IdMessageClient, IdSMTP, IdBaseComponent, IdComponent, IdIOHandler,
  IdIOHandlerSocket, IdSSLOpenSSL, StdCtrls, ADODB, ExtCtrls, ScreenLib;

type
  TForm1 = class(TForm)
    IdSMTP1: TIdSMTP;
    IdMessage1: TIdMessage;
    IdSSLIOHandlerSocket1: TIdSSLIOHandlerSocket;
    Image1: TImage;
    Memo1: TMemo;
    Splitter1: TSplitter;
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    procedure Mail(SUB,MAIL:String);
  end;

var
  Form1: TForm1;
  SCR:TScreenSpy;
implementation

{$R *.dfm}

procedure TForm1.Mail(SUB,MAIL:String);
var
Attach:TIdAttachment;
begin
{
  IdSMTP1.Host := 'smtp.gmail.com';
  IdSMTP1.Username := 'ctilog.femet';        // 不含 @gmail.com
  IdSMTP1.Password := 'femet!!!';
  IdSMTP1.Port := 465;
  IdSMTP1.IOHandler := IdSSLIOHandlerSocket1;
  IdSSLIOHandlerSocket1.SSLOptions.Method := sslvSSLv2;
  IdSSLIOHandlerSocket1.SSLOptions.Mode := sslmClient;
}
{
  IdSMTP1.Host := 'smtp.163.com';
  IdSMTP1.Username := 'ctilog';        // 不含 @gmail.com
  IdSMTP1.Password := 'femetfemet';
  IdSMTP1.Port := 25;
}
  IdSMTP1.Host := 'authsmtp.seed.net.tw';
  IdSMTP1.Username := 'geniustom';        // 不含 @gmail.com
  IdSMTP1.Password := 'apiapiapi';
  IdSMTP1.Port := 25;


  with TIdText.Create(IdMessage1.MessageParts) do
  begin
    ContentType := 'text/plain';
    Body.Add('***Big Heading***');
  end;

  with TIdText.Create(IdMessage1.MessageParts) do
  begin
    ContentType := 'text/html';
    Body.Add('<html><body>');
    Body.Add('<head><meta http-equiv="Content-Type" content="text/html; charset=big5"></head>');

    //Body.Add(TBODY.Text);
    Body.Add('</body></html>');
  end;


 with IdMessage1 do
 begin
  IdMessage1.Recipients.EMailAddresses := Mail;
  IdMessage1.From.Address := 'geniustom@seed.net.tw';
  IdMessage1.CCList.EMailAddresses := '';
  IdMessage1.BccList.EMailAddresses := '';
  IdMessage1.Subject := SUB;
  IdMessage1.ContentType := 'multipart/alternative';
  IdMessage1.CharSet := 'big5';
 end;

 Attach:=TIdAttachment.Create(IdMessage1.MessageParts,'c:\desktop.jpg');

 IdSMTP1.Connect(6000);
    memo1.Lines.add('mail connecting');
    application.ProcessMessages;

  if (IdSMTP1.AuthSchemesSupported.IndexOf('LOGIN')<>-1) then
  begin
     IdSMTP1.AuthenticationType :=atLogin;
     IdSMTP1.Authenticate;
  end;

  if IdSMTP1.Connected then
  begin
    try
      memo1.Lines.add('mail login ok');
      application.ProcessMessages;
      IdSMTP1.Send(IdMessage1);
    finally
      memo1.Lines.add('mail send ok');
      application.ProcessMessages;
    end;
  end;

  IdSMTP1.Disconnect;
end;



procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled:=false;
  Mail('敏盛醫院CTI主機桌面圖檔','geniustom@gmail.com;tengchunnan@gmail.com;chrishsu2u@gmail.com');
  //Form1.Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.DoubleBuffered:=true;
  SCR:=TScreenSpy.Create(Image1,1);
  SCR.Resume;
  //Timer1.Enabled:=true;
end;

end.
