unit CTI_DataType;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,ExtCtrls,DB, ADODB;

type
  TCTIData = record
    Serial_No         :integer;
    CallerID          :string;
    DTMF_Code         :string;
    Process           :integer;
    ProcessMessage    :string;
    Date_Save	        :TDateTime;
    Date_Process	    :TDateTime;
    Date_Send	        :TDateTime;
    MSG_GWID          :string;
    MSG_DATA          :string;
    MSG_ButtonSite    :string;
    MSG_MSGType       :string;
    MSG_MSGText       :string;
    MSG_GWTime        :TDateTime;
    DLL_ProcessMSG    :string;
    Return_Serial_No  :integer;
  end;








implementation

end.
 