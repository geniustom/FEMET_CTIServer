unit ConsoleCommand;

interface
uses Windows, Messages, SysUtils, Variants, Classes,Forms;

procedure ProcessCommand(command:string);
procedure Log(command:integer;msg:string;Color:integer);
procedure ReportToFile(DataPath:string;MSG:string);
procedure PackLog(id,SorR,command:integer;msg:string;Color:integer);  //SorR  0收到封包 1發送封包

var
  hOutput: THandle;
  sbiAttributes: TConsoleScreenBufferInfo;
  wDefColors: WORD;
  coorCurrent, coorTopLeft: TCoord;
  DataPath:string;
  LogIsBusy:boolean;
  ReportIsBusy:boolean;
const
  LightCyan      = FOREGROUND_GREEN or FOREGROUND_BLUE or FOREGROUND_INTENSITY;
  DarkCyan       = FOREGROUND_GREEN or FOREGROUND_BLUE;
  LightYellow    = FOREGROUND_GREEN or FOREGROUND_Red or FOREGROUND_INTENSITY;
  DarkYellow     = FOREGROUND_GREEN or FOREGROUND_Red;
  LightPurb      = FOREGROUND_BLUE  or FOREGROUND_Red or FOREGROUND_INTENSITY;
  DarkPurb       = FOREGROUND_BLUE  or FOREGROUND_Red;
  LightWhite     = FOREGROUND_GREEN or FOREGROUND_BLUE or FOREGROUND_Red or FOREGROUND_INTENSITY;
  DarkWhite      = FOREGROUND_GREEN or FOREGROUND_BLUE or FOREGROUND_Red;
  LightBlue      = FOREGROUND_BLUE or FOREGROUND_INTENSITY;
  LightRed       = FOREGROUND_Red or FOREGROUND_INTENSITY;
  LightGreen     = FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  Black          = FOREGROUND_GREEN and FOREGROUND_BLUE and FOREGROUND_Red;

implementation
//uses ServerForm;


function GetDateTimeSTR():string;
begin

end;


procedure ReportToFile(DataPath:string;MSG:string);
var
   txt:Textfile;
   FileName:string;
begin
  if ReportIsBusy=true then exit;
  //while ReportIsBusy=true do
  //  application.ProcessMessages;
  ReportIsBusy:=true;
  
  FileName:=formatDatetime('YYYY_MM_DD',now)+'.txt';
  assignfile(txt,DataPath+'\Report\'+FileName);
  if FileExists(DataPath+'\Report\'+FileName)=true then
    append(txt)
  else
    rewrite(txt);
  writeln(txt,MSG);
  closefile(txt);

  ReportIsBusy:=false;
end;


procedure LogToFile(DataPath:string;MSG:string);
var
   txt:Textfile;
   FileName:string;
begin
  if LogIsBusy=true then exit;
//while LogIsBusy=true do
//  application.ProcessMessages;
  LogIsBusy:=true;

  FileName:=formatDatetime('YYYY_MM_DD',now)+'.txt';
  assignfile(txt,DataPath+'\LOG\'+FileName);
  if FileExists(DataPath+'\LOG\'+FileName)=true then
    append(txt)
  else
    rewrite(txt);
  writeln(txt,MSG);
  closefile(txt);

  LogIsBusy:=false;
end;


procedure Log(command:integer;msg:string;Color:integer);
var OutputStr:string;
begin
  hOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  //coorTopLeft.X := 1;
  //coorTopLeft.Y := 1;
   { Read the default colors first. }
  SetConsoleTextAttribute(hOutput,LightWhite);
  GetConsoleScreenBufferInfo(hOutput, sbiAttributes);
  wDefColors := sbiAttributes.wAttributes;
  coorCurrent := sbiAttributes.dwCursorPosition;
  //SetConsoleCursorPosition(hOutput, coorTopLeft);
   Case command of
      0:writeln('################################## 系統訊息 ##################################');
      1:writeln('############################### Server連入連線 ###############################');
      2:writeln('############################### Server收到封包 ###############################');
      3:writeln('############################ 送出資料至 MySQL DB #############################');
      4:writeln('############################# 送出資料至 本機DB ##############################');
   else
   
   end;

   Case command of
      0:SetConsoleTextAttribute(hOutput,LightRed);
      1:SetConsoleTextAttribute(hOutput,LightGreen);
      2:SetConsoleTextAttribute(hOutput,LightYellow);
      3:SetConsoleTextAttribute(hOutput,LightPurb);
      4:SetConsoleTextAttribute(hOutput,LightBlue);
   else
        SetConsoleTextAttribute(hOutput,Color);
   end;
   if command<=5 then
      OutputStr:= FormatdateTime('【yy/mm/dd hh:nn:ss】',now)+msg
   else
      OutputStr:=msg;

   write(OutputStr+#13+#10);
   SetConsoleTextAttribute(hOutput, wDefColors);
   LogToFile(DataPath,OutputStr);
   //writeln('###############################################################################');
  //SetConsoleCursorPosition(hOutput, coorCurrent);
end;




































procedure PackLog(id,SorR,command:integer;msg:string;Color:integer);  //SorR  0收到封包 1發送封包
var
i:integer;
statmsg,buftext,outtxt:string;
begin
     if SorR=0 then
        statmsg:='ID : '+inttostr(id)+' 傳來封包 :'+#10
     else
        statmsg:='ID : '+inttostr(id)+' 送出封包 :'+#10;
     buftext:='';
     for i:=1 to length(msg) do
     begin
        if msg[i]=#13 then outtxt:=outtxt+',' else outtxt:=outtxt+msg[i];
        buftext:= buftext+inttohex(ord(msg[i]),2)+' ';
        if msg[i]=#13 then buftext:=buftext+#10;
     end;
     log(command,statmsg+outtxt+#10+buftext,Color);
end;


procedure ProcessCommand(command:string);
var i:integer;
begin
   command:=AnsiLowerCase(command);
   if command='start' then
   begin
      //form1.Visible:=false;
      //form1.Button4Click(form1);
   end
   else
   if command='close' then
   begin

   end
end;
function _split(vOriStr: AnsiString;vDelimiter: AnsiString): TStrings;
var
  i: Integer;
  s: AnsiString;
begin
  try
     result := TStringList.Create();
     s := Trim(vOriStr);
     repeat
        i := Pos(vDelimiter, s);   //找出第一個Delimiter的索引位置。
        if i = 0 then
           result.Append(s)
        else
        begin       //若找到Delimiter時，則...
           result.Append(Copy(s, 1, i - 1));  //複製Delimiter字串之前的字串。
           Delete(s, 1, i);
        end;
     until i = 0;
  except
     on e: Exception do; //ignore errors.
  end;
end;


function PackStr(Delimiter: AnsiString;endstr: AnsiString;pack:array of Variant): String;
var
  i: Integer;
begin
   result:='';
   for i:=0 to high(pack) do
   begin
      result:=result+string(pack[i])+Delimiter;
   end;
   result:=result+endstr;
end;


end.
