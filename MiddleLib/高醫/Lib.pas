unit Lib;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,DB, ADODB,ConsoleCommand,CTI_DataType,inifiles,forms;

type
  TDBObj=class(TComponent)
  private
    { Private declarations }
  public
    C_SVR,C_USN,C_PWD,C_SID,C_CAT:string;
    C_Port:integer;
    Err_flag:integer;

    Target_SQL: TADOConnection;    //Target DB
    Target_Query: TADOQuery;
    Target_LogTime:integer;

    ShowLinkOk:boolean;
    NowIsLink:boolean;

    procedure Target_DBSetup();
    procedure Target_LinkToDB();
    procedure Target_SQLAfterConnect(Sender: TObject);

  end;

  function LIB_TargetDBIsOK(ShowLogToScreen:boolean):boolean;stdcall;far;
  function LIB_TransferData(var CTI_Data:TCTIData):boolean;stdcall;far;


implementation



function LIB_TargetDBIsOK(ShowLogToScreen:boolean):boolean;stdcall;far;
var
  TDBObject:TDBObj;
  i:integer;
begin
   TDBObject:=TDBObj.Create(nil);
   try
      result:=true;
      TDBObject.ShowLinkOk:=ShowLogToScreen;
      TDBObject.NowIsLink:=false;
      TDBObject.Target_DBSetup();
      TDBObject.Target_LinkToDB();
      for i:=0 to 100 do
      begin
        if TDBObject.NowIsLink=true then break;
        sleep(50);
      end;
      TDBObject.Target_Query.SQL.Text:='select top 1 * from KMUH_Vital';
      TDBObject.Target_Query.Open;
   except                             
      result:=false;
   end;

   freeandnil(TDBObject);
end;


Function AddZero(SS: String; II: Integer):String; //�r��e�ɹs
begin
  If Length(TRIM(SS)) < II Then
  while Length(TRIM(SS)) < II do SS := '0'+SS;
    Result := SS;
  //DEMO:AddZero('870501',7):='0870501'
end;

function GetVitalData(Data:string;DataType:integer):integer;
var
  IsBP:boolean;
begin
  result:=0;

  IsBP:=true;

  //Data:= AddZero(Data,9);
  Data:=trim(Data);

  if( (strtoint(copy(Data,1,3))<>0) and (strtoint(copy(Data,4,9))=0) ) then
    IsBP:=false;

  case DataType of
  1:  if IsBP then result:=strtoint(copy(Data,1,3));
  2:  if IsBP then result:=strtoint(copy(Data,4,3));
  3:  if IsBP then result:=strtoint(copy(Data,7,3));
  4:  if not(IsBP) then result:=strtoint(copy(Data,1,3));
  end;

end;

function LIB_TransferData(var CTI_Data:TCTIData):boolean;stdcall;
var
  TDBObject:TDBObj;
  i:integer;
  TTIME:integer;
begin
  try
    //==========================================================================================�Y�s�u���ѡA�^�Ǧ^�h�٤��ܩ�Q����
    result:=false;
    CTI_Data.Process:=0;
    CTI_Data.DLL_ProcessMSG:='��Ʈw����ŧi����';
    TDBObject:=TDBObj.Create(nil);

    with TDBObject do
    begin

      TTIME:= windows.GetTickCount;
      CTI_Data.DLL_ProcessMSG:='��Ʈw�]�w����';
      Target_DBSetup;

      CTI_Data.DLL_ProcessMSG:='��Ʈw�s�u����';
      Target_LinkToDB;


      CTI_Data.DLL_ProcessMSG:='��Ʈw�d�ߥ���';

      Target_Query.SQL.Text:='select top 1 * from KMUH_Vital';
      Target_Query.Open;
      for i:=0 to 100 do
      begin
        sleep(50);
        if TDBObject.NowIsLink=true then break;
      end;
      TTIME:= windows.GetTickCount- TTIME;
      LOG(5,'����:��Ʈw�s�u����,�Ӯ�:'+inttostr(TTIME)+' ms',LightGreen);
      //==========================================================================================�|�]��H�U,�N���Ʈw�s�u�����`
      Target_LogTime:= windows.GetTickCount;

      LOG(5,'����:[DTMF]='+CTI_Data.DTMF_Code+'[DATA]='+CTI_Data.MSG_DATA,LightGreen);
      LOG(5,'����:[CallID]='+trim(CTI_Data.CallerID)+
        ' [GWID]='+trim(CTI_Data.MSG_GWID)+
        ' [ButID]='+trim(CTI_Data.MSG_ButtonSite),LightGreen);

      CTI_Data.DLL_ProcessMSG:='��Ʈw���J��ƥ���';
      Target_Query.Append;

        //CTI_Data.DLL_ProcessMSG:='gateway_id'+'��Ʈw���J��ƥ���';
      Target_Query.FieldByName('gateway_id').AsString       :=trim(CTI_Data.MSG_GWID);
        //CTI_Data.DLL_ProcessMSG:='button_site_id'+'��Ʈw���J��ƥ���';
      Target_Query.FieldByName('button_site_id').AsString   :=trim(CTI_Data.MSG_ButtonSite);
        //CTI_Data.DLL_ProcessMSG:='data_type'+'��Ʈw���J��ƥ���';
      Target_Query.FieldByName('data_type').AsString        :=trim(CTI_Data.MSG_MSGType);
        //CTI_Data.DLL_ProcessMSG:='measure_time'+'��Ʈw���J��ƥ���';
      Target_Query.FieldByName('measure_time').AsString     :=formatDateTime('yyyy-mm-dd hh:nn:ss',CTI_Data.MSG_GWTime);
        //CTI_Data.DLL_ProcessMSG:='gateway_time'+'��Ʈw���J��ƥ���';
      Target_Query.FieldByName('gateway_time').AsString     :=formatDateTime('yyyy-mm-dd hh:nn:ss',CTI_Data.MSG_GWTime);
        //CTI_Data.DLL_ProcessMSG:='cti_time'+'��Ʈw���J��ƥ���';
      Target_Query.FieldByName('cti_time').AsString         :=formatDateTime('yyyy/mm/dd hh:nn:ss',CTI_Data.Date_Save);
        //CTI_Data.DLL_ProcessMSG:='gateway_telno'+'��Ʈw���J��ƥ���';
      Target_Query.FieldByName('gateway_telno').AsString    :=trim(CTI_Data.CallerID);

      Target_Query.FieldByName('upload_status').AsString    :='0';
            
      LOG(5,'����:��Ʃ� '+TDBObject.Target_Query.FieldByName('cti_time').AsString+' �ɶi�JCTI���˹��',LightGreen);
      LOG(5,'����:[MSG]='+trim(CTI_Data.MSG_MSGText)+
        ' �� '+TDBObject.Target_Query.FieldByName('measure_time').AsString+' �ɵo��',LightGreen);

      if trim(CTI_Data.MSG_MSGType)='50' then
      begin
          //CTI_Data.DLL_ProcessMSG:='vital_sign_1='+inttostr(GetVitalData(CTI_Data.MSG_DATA,1))+'��Ʈw���J��ƥ���';
        Target_Query.FieldByName('vital_sign_1').AsInteger    :=GetVitalData(CTI_Data.MSG_DATA,1);
          //CTI_Data.DLL_ProcessMSG:='vital_sign_2='+inttostr(GetVitalData(CTI_Data.MSG_DATA,2))+'��Ʈw���J��ƥ���';
        Target_Query.FieldByName('vital_sign_2').AsInteger    :=GetVitalData(CTI_Data.MSG_DATA,2);
          //CTI_Data.DLL_ProcessMSG:='vital_sign_3='+inttostr(GetVitalData(CTI_Data.MSG_DATA,3))+'��Ʈw���J��ƥ���';
        Target_Query.FieldByName('vital_sign_3').AsInteger    :=GetVitalData(CTI_Data.MSG_DATA,3);
          //CTI_Data.DLL_ProcessMSG:='vital_sign_4='+inttostr(GetVitalData(CTI_Data.MSG_DATA,4))+'��Ʈw���J��ƥ���';
        Target_Query.FieldByName('vital_sign_4').AsInteger    :=GetVitalData(CTI_Data.MSG_DATA,4);

        LOG(5,'����:[���Y��]='+inttostr(TDBObject.Target_Query.FieldByName('vital_sign_1').AsInteger)+
          ' [�αi��]='+inttostr(TDBObject.Target_Query.FieldByName('vital_sign_2').AsInteger)+
          ' [�߸�]='+inttostr(TDBObject.Target_Query.FieldByName('vital_sign_3').AsInteger)+
          ' [��}]='+inttostr(TDBObject.Target_Query.FieldByName('vital_sign_4').AsInteger),LightGreen);
      end;


      CTI_Data.DLL_ProcessMSG:=CTI_Data.DLL_ProcessMSG+'->��Ʈw�g�J��ƥ���';
      Target_Query.Post;
    end;
  except
    CTI_Data.ProcessMessage:=CTI_Data.ProcessMessage+CTI_Data.DLL_ProcessMSG;
    LOG(5,'����:'+CTI_Data.DLL_ProcessMSG,LightGreen);
    exit;
  end;
  result:=true;

  CTI_Data.Date_Process:=strtodatetime(formatDateTime('yyyy/mm/dd hh:nn:ss',now));
  CTI_Data.ProcessMessage:=CTI_Data.ProcessMessage+'->�ɱ�����ഫ����';
  TDBObject.Target_LogTime:= windows.GetTickCount- TDBObject.Target_LogTime;
  LOG(5,'����:�ɱ�����ഫ����,�Ӯ�:'+inttostr(TDBObject.Target_LogTime)+' ms',LightGreen);
  CTI_Data.Process:=1;
  CTI_Data.Return_Serial_No:=TDBObject.Target_Query.FieldByName('id').AsInteger; //�^��ID

  freeandnil(TDBObject);
end;

procedure TDBObj.Target_SQLAfterConnect(Sender: TObject);
begin
  Target_LogTime:= windows.GetTickCount- Target_LogTime;
  NowIsLink:=true;
  if ShowLinkOk then LOG(5,'����:SQL Server�s�u����,�Ӯ�:'+inttostr(Target_LogTime)+' ms',LightGreen);
end;



procedure TDBObj.Target_DBSetup();
var
  ConfigINI:tinifile;
begin
  ConsoleCommand.DataPath:=ExtractFilePath(Application.ExeName);

  Target_SQL:=TADOConnection.Create(self);
  Target_SQL.AfterConnect:=Target_SQLAfterConnect;

  Target_Query:=TADOQuery.Create(self);
  Target_Query.Connection:=Target_SQL;

  Err_flag:=0;

  Target_LogTime:=windows.GetTickCount;
//===========================================================
  if ShowLinkOk then LOG(5,'����:������夶���ʺA�s���禡�w��l��',LightGreen);
  ConfigINI:=tinifile.create(DataPath+'Config.ini');
//============================================================
  Target_LogTime:= windows.GetTickCount- Target_LogTime;
//===========================================================CTI DB
  C_SVR          := ConfigINI.ReadString('MCHSQL','IP','192.168.0.244');
  C_USN          := ConfigINI.ReadString('MCHSQL','ID','sa');
  C_PWD          := ConfigINI.ReadString('MCHSQL','PWD','0000');
  C_CAT          := ConfigINI.ReadString('MCHSQL','CAT','Temp_DB');

  ConfigINI.WriteString('MCHSQL','IP',C_SVR);
  ConfigINI.WriteString('MCHSQL','ID',C_USN);
  ConfigINI.WriteString('MCHSQL','PWD',C_PWD);
  ConfigINI.WriteString('MCHSQL','CAT',C_CAT);

  ConfigINI.UpdateFile;

  if ShowLinkOk then LOG(5,'����:������夶���ʺA�s���禡�w���J����,�Ӯ�:'+inttostr(Target_LogTime)+' ms',LightGreen);
end;


procedure TDBObj.Target_LinkToDB();
begin
//===========================================================CTI DB �}��
  try
    if ShowLinkOk then LOG(5,'����:���JMS SQL�X�ʵ{��',LightGreen);
    if ShowLinkOk then LOG(5,'����:IP='+C_SVR+' ID='+C_USN+' PWD='+C_PWD+' CAT='+C_CAT,LightGreen);
    if ShowLinkOk then LOG(5,'����:DB�s�u��',LightGreen);
    Target_LogTime:=windows.GetTickCount;
    Target_SQL.CommandTimeout:=5;
    Target_SQL.ConnectionString:='Provider=SQLOLEDB.1;Persist Security Info=True;';
    Target_SQL.ConnectionString:=Target_SQL.ConnectionString+'Initial Catalog='+C_CAT+';Data Source='+C_SVR+';User ID='+C_USN+';Password='+C_PWD+';';
    Target_SQL.Open;
  except
    LOG(5,'����:DB�s�u����',LightGreen);
    Err_flag:=1;
  end;
//===========================================================�i�J�u�@�Ҧ�
  if Err_flag=0 then
  begin
     if ShowLinkOk then LOG(5,'����:��Ʈw�s�u����,�i�J�u�@�Ҧ�',LightGreen);
  end;
end;





end.































{
procedure TDBObj.CTI_SQLAfterConnect(Sender: TObject);
begin
  CTI_LogTime:= windows.GetTickCount- CTI_LogTime;
  NowIsLink:=true;
  if ShowLinkOk then LOG(5,'����:SQL Server�s�u����,�Ӯ�:'+inttostr(CTI_LogTime)+' ms',LightGreen);
end;

procedure TDBObj.CTI_SQLDisconnect(Connection: TADOConnection;var EventStatus: TEventStatus);
begin
   if CTI_SQL.Connected=false then exit;
   CTI_SQL.Close;
end;


procedure TDBObj.CTI_LinkToDB();
begin

end;

procedure TDBObj.CTI_DBSetup();
var
  ConfigINI:tinifile;
begin

  ConsoleCommand.DataPath:=ExtractFilePath(Application.ExeName);

  CTI_SQL:=TADOConnection.Create(self);
  CTI_SQL.OnDisconnect:=CTI_SQLDisconnect;
  CTI_SQL.AfterConnect:=CTI_SQLAfterConnect;

  CTI_Query:=TADOQuery.Create(self);


  CTI_SQL.Close;
  Err_flag:=0;

  CTI_LogTime:=windows.GetTickCount;
//===========================================================
  if ShowLinkOk then LOG(5,'����:������夶���ʺA�s���禡�w��l��',LightGreen);
  ConfigINI:=tinifile.create(DataPath+'Config.ini');
//============================================================
  LogTime:= windows.GetTickCount- LogTime;
//===========================================================CTI DB
  C_SVR          := ConfigINI.ReadString('CTISQL','IP','192.168.0.244');
  C_USN          := ConfigINI.ReadString('CTISQL','ID','sa');
  C_PWD          := ConfigINI.ReadString('CTISQL','PWD','0000');
  C_CAT          := ConfigINI.ReadString('CTISQL','CAT','TempDB');

  ConfigINI.WriteString('CTISQL','IP',C_SVR);
  ConfigINI.WriteString('CTISQL','ID',C_USN);
  ConfigINI.WriteString('CTISQL','PWD',C_PWD);
  ConfigINI.WriteString('CTISQL','CAT',C_CAT);

  ConfigINI.UpdateFile;

  if ShowLinkOk then LOG(5,'����:������夶���ʺA�s���禡�w���J����,�Ӯ�:'+inttostr(LogTime)+' ms',LightGreen);

end;
}
