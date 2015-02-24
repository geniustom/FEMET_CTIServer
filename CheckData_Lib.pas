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
   1:   result:='主機電量不足';
   2:   result:='主機電源異常';
   50:  result:='生理傳輸資料';
   52:  result:='客服求援需求';
   53:  result:='主機系統回報';
   54:  result:='壓扣電量不足';
   55:  result:='RFID上傳資訊';
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

   //result:=strtodatetime(DBTime); //讀取CTI時間用，若要讀GATEWAY的時間，此行須MARK

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

function CheckDataIsRight(Data:string):boolean;   //資料正確TRUE，錯誤FALSE
const
  NumIndex:array [1..25]of integer=(2,3,4,5,6,7,8,9,10,11,12,13,14,16,17,18,19,20,21,22,23,24,25,26,27);
var
  CheckSUM,i:integer;
begin
  result:=false;
  if (Pos('*',Data)<>1) then exit;
  if (Pos('#',Data)<>15) then exit;
  if strtoint(copy(Data,16,2))>9 then exit;  //壓扣編號
  if (strtoint(copy(Data,18,2)) in [1,2,3,50,51,52,53,54,55])=false then exit;     //訊息代碼
  CheckSUM:=0;
  for i:=1 to 25 do
  begin
     if (ord(Data[NumIndex[i]])<$30) or (ord(Data[NumIndex[i]])>$3A) then exit;
     CheckSUM:=CheckSUM+strtoint(Data[NumIndex[i]]);
  end;
  if (ord(Data[28])<$30) or (ord(Data[28])>$3A) then exit;    //檢查最後一碼
  if strtoint(Data[28])<>(CheckSUM mod 10) then exit;         //CHECKSUM錯誤

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
  if GetMSGType(Data)=50 then      //生理資料上傳
  begin
    MEASURE_DATA:=strtoint(GetMeasureData(Data));
    MEA_PULSE:= MEASURE_DATA mod 1000;
    MEASURE_DATA:=(MEASURE_DATA-MEA_PULSE) div 1000;
    MEA_BP:=MEASURE_DATA mod 1000;
    MEASURE_DATA:=(MEASURE_DATA-MEA_BP) div 1000;
    MEA_SP:=MEASURE_DATA;
    if((MEA_PULSE=0)and(MEA_BP=0)) then //==================血糖
    begin
      //if MEA_SP<=80 then exit;   不做此判斷
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
   DataNoDup:boolean; //資料是否重複
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
          if GetMSGText(MSGList.Strings[i])='RFID上傳資訊' then
          begin
             RFIDHexCode:=GetMeasureData(MSGList.Strings[i]);
             RFIDHexCode:=inttohex(strtoint(trim(RFIDHexCode)),6);
             DataQuery.FieldByName('MSG_RFID_Data').AsString:=RFIDHexCode;
          end;
          DataQuery.FieldByName('MSG_GWTime').AsDateTime:=GetNodeTime(TimeSTR,MSGList.Strings[i]);
          if DataNoDup=true then
          begin
            DataQuery.FieldByName('Process').AsInteger:=0;
            DataQuery.FieldByName('ProcessMessage').AsString:='分析完成';
            LOG(5,'CTIDB: 第 '+inttostr(index)+' 筆,第 '+inttostr(i)+' 分段: 封包正確,放入等待佇列:',LightYellow);
          end
          else
          begin
            DataQuery.FieldByName('Process').AsInteger:=1;
            DataQuery.FieldByName('ProcessMessage').AsString:='資料重複';
            LOG(5,'CTIDB: 第 '+inttostr(index)+' 筆,第 '+inttostr(i)+' 分段: 資料重複，不予處理',LightYellow);
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
          DataQuery.FieldByName('ProcessMessage').AsString:='封包有誤';

          LOG(5,'CTIDB: 第 '+inttostr(index)+' 筆,第 '+inttostr(i)+' 分段: 封包有誤,放入偵錯佇列:',DarkYellow);
          LOG(5,'CTIDB:[TEL]:'+MSGList.Strings[0]+' [MSG]:'+MSGList.Strings[i],DarkYellow);
          LOG(6,'------------------------------------------------------------------------',Darkcyan);
          DataQuery.Post;
          application.ProcessMessages;
        except
        end;
      end;

      try
        //============取出DBID=============
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
 