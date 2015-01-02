unit LibForm;

interface

uses
  ShareMem,Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ADODB,ConsoleCommand,inifiles;

type
  TMinSheng = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public

  end;
  


var
  MinSheng: TMinSheng;
    
implementation
uses Lib;

{$R *.dfm}

procedure TMinSheng.FormCreate(Sender: TObject);
begin
   showmessage('ok');
   LIB_IninTargetDB();
   LIB_TargetDBIsOK();
end;

end.





