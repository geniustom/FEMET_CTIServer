library MinShengLib;
//program MinShengLib;
{$APPTYPE CONSOLE}
uses
  ShareMem,
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  ScktComp,
  Forms,
  Dialogs,
  ConsoleCommand in '..\ConsoleCommand.pas',
  Lib in 'Lib.pas',
  CTI_DataType in '..\CTI_DataType.pas';

{$R *.res}





exports
LIB_TargetDBIsOK,
LIB_TransferData;



begin
  //Application.Initialize;
  //Application.CreateForm(TMinSheng, MinSheng);
  //Application.Run;
  //LIB_TargetDBIsOK();
end.
