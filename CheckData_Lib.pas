unit CheckData_Lib;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,inifiles,
  ExtCtrls,DB, ADODB,{DBAccess,}ShellAPI;

function CheckDataIsRight(Data:string):boolean;
function GetNodeTime(DBTime,msg:string):TDateTime;
function GetMSGType(msg:string):integer;
function GetMSGText(msg:string):string;
function GetButtonSite(msg:string):integer;
function GetGateWayID(msg:string):string;
function GetMeasureData(msg:string):string;
procedure StrToDB(var DataQuery:TADOQuery;index:integer;STRList:String);
function ProcessPacket(Data:String):string;

implementation
uses ConsoleCommand,ServerForm;

function GetMSGText(msg:string):string;
begin
   case GetMSGType(msg) of
   1:   result:='�D���q�q����';
   2:   result:='�D���q�����`';
   50:  result:='�Ͳz�ǿ���';
   52:  result:='�ȪA�D���ݨD';
   53:  result:='�D���t�Φ^��';
   54:  result:='�����q�q����';
   55:  result:='RFID�W�Ǹ�T';
   end;
end;


function GetNodeTime(DBTime,msg:string):TDateTime;
var
TimeValue:integer;
Y,M,D,H,N:integer;
begin
   TimeValue:=strtoint(copy(msg,20,8));
   N:= TimeValue mod 60;

   TimeValue:=(TimeValue-N) div 60;
   H:=TimeValue mod 24;

   TimeValue:=(TimeValue-H) div 24;
   D:=(TimeValue mod 32);

   TimeValue:=(TimeValue-D) div 32;
   M:=TimeValue mod 13;

   TimeValue:=(TimeValue-M) div 13;
   Y:=TimeValue+2000;
   try
      result:=strtodatetime(inttostr(Y)+'/'+
                         inttostr(M)+'/'+
                         inttostr(D)+' '+
                         inttostr(H)+':'+
                         inttostr(N));
   except
      on EConvertError do
      begin
        result:=strtoDatetime(DBTime);
      end;
   end;

   //result:=strtodatetime(DBTime); //Ū��CTI�ɶ��ΡA�Y�nŪGATEWAY���ɶ��A���涷MARK

end;


function GetMSGType(msg:string):integer;
begin
   result:=strtoint(copy(msg,18,2));
end;

function GetButtonSite(msg:string):integer;
begin
   result:=strtoint(copy(msg,16,2));
end;

function GetGateWayID(msg:string):string;
begin
   result:=copy(msg,2,4);
end;

function GetMeasureData(msg:string):string;
var temp:string;
begin
   temp:=copy(msg,6,9);
   result:=temp;
end;

function CheckDataIsRight(Data:string):boolean;   //��ƥ��TTRUE�A���~FALSE
const
  NumIndex:array [1..25]of integer=(2,3,4,5,6,7,8,9,10,11,12,13,14,16,17,18,19,20,21,22,23,24,25,26,27);
var
  CheckSUM,i:integer;
begin
  result:=false;
  if (Pos('*',Data)<>1) then exit;
  if (Pos('#',Data)<>15) then exit;
  if strtoint(copy(Data,16,2))>9 then exit;  //�����s��
  if (strtoint(copy(Data,18,2)) in [1,2,3,50,51,52,53,54,55])=false then exit;     //�T���N�X
  CheckSUM:=0;
  for i:=1 to 25 do
  begin
     if (ord(Data[NumIndex[i]])<$30) or (ord(Data[NumIndex[i]])>$3A) then exit;
     CheckSUM:=CheckSUM+strtoint(Data[NumIndex[i]]);
  end;
  if (ord(Data[28])<$30) or (ord(Data[28])>$3A) then exit;    //�ˬd�̫�@�X
  if strtoint(Data[28])<>(CheckSUM mod 10) then exit;         //CHECKSUM���~

  result:=true;
end;

function CheckMSGIsError(Data:string):boolean;
var
  MEASURE_DATA,MEA_SP, MEA_BP, MEA_PULSE,MEA_AC:integer;
begin
  result:=true;
//==================================================================
  if CheckDataIsRight(Data)=false then exit;
//==================================================================
  if GetMSGType(Data)=50 then      //�Ͳz��ƤW��
  begin
    MEASURE_DATA:=strtoint(GetMeasureData(Data));
    MEA_PULSE:= MEASURE_DATA mod 1000;
    MEASURE_DATA:=(MEASURE_DATA-MEA_PULSE) div 1000;
    MEA_BP:=MEASURE_DATA mod 1000;
    MEASURE_DATA:=(MEASURE_DATA-MEA_BP) div 1000;
    MEA_SP:=MEASURE_DATA;
    if((MEA_PULSE=0)and(MEA_BP=0)) then //==================��}
    begin
      //if MEA_SP<=80 then exit;   �������P�_
    end;
  end;
//==================================================================
  result:=false;
end;



procedure StrToDB(var DataQuery:TADOQuery;index:integer;STRList:String);
var
   i:integer;
   MSGList:TStringList;
   TimeSTR:string;
   DBID:integer;
   DataPath:string;
   ConnectIsOK,PostOK:integer;
   DataNoDup:boolean; //��ƬO�_����
   RFIDHexCode:string;
begin
   DataPath:=ExtractFilePath(Application.ExeName);
   MSGList:= TStringList.Create;
   MSGList.Delimiter:=',';
   MSGList.DelimitedText:=STRList;
   TimeSTR:=FormatDateTime('yyyy/mm/dd hh:nn:ss',now);

   for i:=1 to MSGList.Count-1 do
   begin
      //============ACCESS DB============
      if CheckMSGIsError(MSGList.Strings[i])=false then
      begin
        DataQuery.SQL.Text:='select * from Gateway_Data_Process where CallerID='''+MSGList.Strings[0]+''' and DTMF_Code='''+MSGList.Strings[i]+'''';
        DataQuery.open;
        DataNoDup:=DataQuery.EOF;
        DataQuery.Close;
        DataQuery.SQL.Text:='select Top 1 * from Gateway_Data_Process';
        try
          DataQuery.open;
          DataQuery.Append;

          DataQuery.FieldByName('CallerID').AsString:=MSGList.Strings[0];
          DataQuery.FieldByName('DTMF_Code').AsString:=MSGList.Strings[i];
          DataQuery.FieldByName('Date_Save').AsDateTime:=strtodatetime(TimeSTR);
          DataQuery.FieldByName('MSG_GWID').AsString:=GetGateWayID(MSGList.Strings[i]);
          DataQuery.FieldByName('MSG_DATA').AsString:=GetMeasureData(MSGList.Strings[i]);
          DataQuery.FieldByName('MSG_Buttonsite').AsInteger:=GetButtonSite(MSGList.Strings[i]);
          DataQuery.FieldByName('MSG_MSGType').AsInteger:=GetMSGType(MSGList.Strings[i]);
          DataQuery.FieldByName('MSG_MSGText').AsString:=GetMSGText(MSGList.Strings[i]);
          if GetMSGText(MSGList.Strings[i])='RFID�W�Ǹ�T' then
          begin
             RFIDHexCode:=GetMeasureData(MSGList.Strings[i]);
             RFIDHexCode:=inttohex(strtoint(trim(RFIDHexCode)),6);
             DataQuery.FieldByName('MSG_RFID_Data').AsString:=RFIDHexCode;
          end;
          DataQuery.FieldByName('MSG_GWTime').AsDateTime:=GetNodeTime(TimeSTR,MSGList.Strings[i]);
          if DataNoDup=true then
          begin
            DataQuery.FieldByName('Process').AsInteger:=0;
            DataQuery.FieldByName('ProcessMessage').AsString:='���R����';
            LOG(5,'CTIDB: �� '+inttostr(index)+' ��,�� '+inttostr(i)+' ���q: �ʥ]���T,��J���ݦ�C:',LightYellow);
          end
          else
          begin
            DataQuery.FieldByName('Process').AsInteger:=1;
            DataQuery.FieldByName('ProcessMessage').AsString:='��ƭ���';
            LOG(5,'CTIDB: �� '+inttostr(index)+' ��,�� '+inttostr(i)+' ���q: ��ƭ��ơA�����B�z',LightYellow);
          end;

          LOG(5,'CTIDB:[TEL]:'+MSGList.Strings[0]+' [MSG]:'+MSGList.Strings[i],LightYellow);
          LOG(6,'------------------------------------------------------------------------',Darkcyan);
          DataQuery.Post;
          application.ProcessMessages;
        except
        end;
      end
      else
      begin
        DataQuery.SQL.Text:='select Top 1 * from Gateway_Data_Error';
        try
          DataQuery.open;
          DataQuery.Append;

          DataQuery.FieldByName('CallerID').AsString:=MSGList.Strings[0];
          DataQuery.FieldByName('DTMF_Code').AsString:=MSGList.Strings[i];
          DataQuery.FieldByName('Date_Save').AsDateTime:=strtodatetime(TimeSTR);
          DataQuery.FieldByName('Process').AsInteger:=0;
          DataQuery.FieldByName('ProcessMessage').AsString:='�ʥ]���~';

          LOG(5,'CTIDB: �� '+inttostr(index)+' ��,�� '+inttostr(i)+' ���q: �ʥ]���~,��J������C:',DarkYellow);
          LOG(5,'CTIDB:[TEL]:'+MSGList.Strings[0]+' [MSG]:'+MSGList.Strings[i],DarkYellow);
          LOG(6,'------------------------------------------------------------------------',Darkcyan);
          DataQuery.Post;
          application.ProcessMessages;
        except
        end;
      end;

      try
        //============���XDBID=============
        DBID:= DataQuery.FieldByName('Serial_NO').AsInteger;
        //============QUEUE================
        DataQuery.Close;
      except
      end;
   end;
end;


function ProcessPacket(Data:String):string;
var
TempData,ResultData:TStringList;
Tel,Temp:string;
i,DataCount:integer;
begin
  TempData:=TStringList.Create;
  TempData.Delimiter:=',';
  TempData.DelimitedText:=Data;

  ResultData:=TStringList.Create;
  ResultData.Delimiter:=',';

  Tel:=TempData.Strings[0];
  TempData.Delete(0);

  for i:=TempData.Count-1 to 0 do
  begin
    if TempData.Strings[i]='99999999999999' then
    begin
       TempData.Delete(i);
    end;
  end;

  DataCount:= TempData.Count div 2;
  for i:=0 to DataCount-1 do
  begin
     ResultData.Add(TempData.Strings[i*2]+TempData.Strings[i*2+1]);
  end;

  for i:=0 to ResultData.Count -1 do
  begin
     Temp:=ResultData.Strings[i];
     //delete(Temp,1,1);
     //delete(Temp,14,1);
     //delete(Temp,26,1);
     ResultData.Strings[i]:=Temp;
     //showmessage(ResultData.Strings[i]);
  end;

  ResultData.Insert(0,Tel);
  result:=ResultData.DelimitedText;
end;

end.
 