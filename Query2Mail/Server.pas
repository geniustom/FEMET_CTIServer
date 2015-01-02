unit Server;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, MemDS, DBAccess, Ora,IdMessage, IdTCPConnection, IdTCPClient,
  IdMessageClient, IdSMTP, IdBaseComponent, IdComponent, IdIOHandler,
  IdIOHandlerSocket, IdSSLOpenSSL, StdCtrls, ADODB;

type
  TForm1 = class(TForm)
    OraSession1: TOraSession;
    IdSMTP1: TIdSMTP;
    IdMessage1: TIdMessage;
    IdSSLIOHandlerSocket1: TIdSSLIOHandlerSocket;
    OraQuery1: TOraQuery;
    Memo1: TMemo;
    ADO: TADOConnection;
    ADOQ: TADOQuery;

    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    procedure Mail(SUB,MAIL:String;TBODY:Tstringlist);
    procedure CMDToOracel(ParmStr:TStringlist);
    procedure CMDToSQL(ParmStr:TStringlist);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Mail(SUB,MAIL:String;TBODY:Tstringlist);

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

    Body.Add(TBODY.Text);
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
  close;
end;

function OutputADOTOHtml(Query:TADOQuery):TStringList;
var
  myStringlist:Tstringlist;
  nCnt:integer;
  CNT:integer;
begin
  myStringlist:=TStringList.Create;
  myStringlist.Delimiter:=#13;
  myStringlist.Add('<STYLE>td{font-family: "Verdana", "Arial", "Helvetica", "sans-serif";font-size: 10pt; text-align: center; vertical-align: middle; padding-top: 2px; padding-right: 2px; padding-left: 2px; color: #333333; padding-top: 5px; padding-bottom: 3px;}</STYLE>');

  myStringlist.Add('<TABLE border="1" align="center" cellpadding="0" cellspacing="1" bordercolor="#666666" bgcolor="#FFFFFF" id="AutoNumber1" style="border-collapse: collapse">');
  myStringlist.Add('<TR class="tt" align="center" bgcolor="#FFCC99">');
  myStringlist.Add('<TD nowrap bgcolor="#FFCC99">編號</TD>');
  for nCnt:=0 to Query.FieldCount -1 do
     begin
         myStringlist.Add('<TD nowrap bgcolor="#FFCC99">'+Query.Fields[nCnt].FieldName+'</TD>');
     end;

  myStringlist.Add('</TR>');
  CNT:=0;
  while not Query.Eof do
  begin
    CNT:=CNT+1;
    if CNT mod 2=0 then
      myStringlist.Add('<TR class="tt">')
    else
      myStringlist.Add('<TR class="tt" bgcolor="#cccccc">');

    myStringlist.Add('<TD bordercolor="#000000" bgcolor="#FFCC66">'+inttostr(CNT)+'</TD>');
    for nCnt:=0 to Query.FieldCount -1 do
    begin
      myStringlist.Add('<TD bordercolor="#003333">'+Query.Fields[nCnt].AsString +'</TD>');
    end;
    myStringlist.Add('</TR>');
    Query.Next;
  end;

  myStringlist.Add('</Table>');

  result:= myStringlist;

end;

function OutputTOHtml(Query:TOraQuery):TStringList;
var
  myStringlist:Tstringlist;
  nCnt:integer;
  CNT:integer;
begin
  myStringlist:=TStringList.Create;
  myStringlist.Delimiter:=#13;
  myStringlist.Add('<STYLE>td{font-family: "Verdana", "Arial", "Helvetica", "sans-serif";font-size: 10pt; text-align: center; vertical-align: middle; padding-top: 2px; padding-right: 2px; padding-left: 2px; color: #333333; padding-top: 5px; padding-bottom: 3px;}</STYLE>');

  myStringlist.Add('<TABLE border="1" align="center" cellpadding="0" cellspacing="1" bordercolor="#666666" bgcolor="#FFFFFF" id="AutoNumber1" style="border-collapse: collapse">');
  myStringlist.Add('<TR class="tt" align="center" bgcolor="#FFCC99">');
  myStringlist.Add('<TD nowrap bgcolor="#FFCC99">編號</TD>');
  for nCnt:=0 to Query.FieldCount -1 do
     begin
         myStringlist.Add('<TD nowrap bgcolor="#FFCC99">'+Query.Fields[nCnt].FieldName+'</TD>');
     end;

  myStringlist.Add('</TR>');
  CNT:=0;
  while not Query.Eof do
  begin
    CNT:=CNT+1;
    if CNT mod 2=0 then
      myStringlist.Add('<TR class="tt">')
    else
      myStringlist.Add('<TR class="tt" bgcolor="#cccccc">');

    myStringlist.Add('<TD bordercolor="#000000" bgcolor="#FFCC66">'+inttostr(CNT)+'</TD>');
    for nCnt:=0 to Query.FieldCount -1 do
    begin
      myStringlist.Add('<TD bordercolor="#003333">'+Query.Fields[nCnt].AsString +'</TD>');
    end;
    myStringlist.Add('</TR>');
    Query.Next;
  end;

  myStringlist.Add('</Table>');

  result:= myStringlist;

end;

procedure TForm1.CMDToSQL(ParmStr:TStringlist);
begin
  ADO.ConnectionString:='Provider=SQLOLEDB.1;Persist Security Info=True;Initial Catalog='+ParmStr.Strings[3]+';';
  ADO.ConnectionString:=ADO.ConnectionString+'Data Source='+ParmStr.Strings[1]+','+ParmStr.Strings[2]+
                        ';User ID='+ParmStr.Strings[4]+';Password='+ParmStr.Strings[5]+';';
  memo1.Lines.add('MS SQL opening');
  application.ProcessMessages;
  ADO.Open;
  ADOQ.SQL.Text:=ParmStr.Strings[6];
  memo1.Lines.add('sql opening');
  memo1.Lines.add(ADOQ.SQL.Text);
  application.ProcessMessages;

  ADOQ.Open;
   if ADOQ.eof<>true then
   begin
    memo1.Lines.add('sql ok');
    application.ProcessMessages;
    //Mail('敏盛醫院CTI主機LOG回報',ParmStr.Strings[7],OutputADOTOHtml(ADOQ));
    Mail(ParmStr.Strings[8],ParmStr.Strings[7],OutputADOTOHtml(ADOQ));
   end;
end;


procedure TForm1.CMDToOracel(ParmStr:TStringlist);
begin
   OraSession1.ConnectString:=ParmStr.Strings[4]+'/'+ParmStr.Strings[5]+'@'+ParmStr.Strings[1]+':'+ParmStr.Strings[2]+':'+ParmStr.Strings[3];
   memo1.Lines.add('oracle opening');
   application.ProcessMessages;

   OraSession1.Open;
   OraQuery1.SQL.Text:=ParmStr.Strings[6];
   memo1.Lines.add('sql opening');
   memo1.Lines.add(OraQuery1.SQL.Text);
   application.ProcessMessages;
   OraQuery1.Open;

   if OraQuery1.eof<>true then
   begin
    memo1.Lines.add('sql ok');
    application.ProcessMessages;
    //Mail('市政府CTI主機LOG回報',ParmStr.Strings[7],OutputTOHtml(OraQuery1));
    Mail(ParmStr.Strings[8],ParmStr.Strings[7],OutputTOHtml(OraQuery1));
   end;
end;


procedure TForm1.FormActivate(Sender: TObject);
var
MSGList:TStringlist;
i:integer;
Body:Tstrings;
begin
   MSGList:=TStringlist.Create;
   MSGList.Delimiter:=',';

   for i:=0 to ParamCount do
   begin
      MSGList.Add(ParamStr(i));
   end;
   //PATH,IP,PORT,SID,USN,PWD,SQL,MAIL,MAILTITTLE
   //  0   1   2   3   4   5   6   7       8

   if MSGList.Count<>9 then
   begin
      SELF.Close;
      exit;
   end;

   CMDToSQL(MSGList);

   CLOSE;

end;

end.
