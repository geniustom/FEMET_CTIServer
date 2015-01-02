unit ScreenLib;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, MemDS, DBAccess, Ora,IdMessage, IdTCPConnection, IdTCPClient,
  IdMessageClient, IdSMTP, IdBaseComponent, IdComponent, IdIOHandler,
  IdIOHandlerSocket, IdSSLOpenSSL, StdCtrls,ExtCtrls, ADODB,jpeg,math;

type


  TScreenSpy = class(TThread)
  private
    RefreshSeconds:integer;
    FPixelFormat: TPixelFormat;
    FDC:HDC;
    function ProcessSCNDC(Rate:double):HDC;
  protected
    procedure Execute; override;
  public
    FWidth:Integer;
    FHeight:Integer;
    DCBMP:TBitmap;
    procedure GetFirst;

    constructor Create(var IMG:Timage;RefreshTime:integer); reintroduce;

  end;


implementation
uses Server;

constructor TScreenSpy.Create(var IMG:Timage;RefreshTime:integer);
begin
  FreeOnTerminate := True;
  FWidth:= GetSystemMetrics(SM_CXSCREEN);
  FHeight:= GetSystemMetrics(SM_CYSCREEN);
  DCBMP:=TBitmap.Create;

  RefreshSeconds:=RefreshTime;
  inherited Create(True);
end;


//�o�ӥ\��i�H�N BMP / JPG ���Y���A���w���j�p�Ϋ~�誺 JPG �榡�A�A�i�H�N���s�ɡA�s�b�ƾڮw�A�Ʀܩ�i TStream �q�L ISAPI �����ǵ��ϥΪ� Browser �@����ܹ��ɡC
function StretchImage(out IMG:TImage;Width, Height, Quality : Integer) : TJpegImage;
var
    tempbmp : TBitmap;
    RT : TRect;
begin
    result := TjpegImage.Create;
    tempbmp := TBitmap.Create;

    RT.Left := 0;
    RT.Top := 0;
    RT.Right := Width - 1;
    RT.Bottom := Height - 1;
    try
      result.CompressionQuality := Quality;
      result.Assign(IMG.picture.Bitmap);
    finally
      tempbmp.Free;
    end;
end;

procedure TScreenSpy.Execute;
var JPG:TJpegImage;
begin
  while true  do
  begin
    try
      GetFirst;
    except
    end;
    //JPG:= StretchImage(TImg,FWidth,FHeight,100);
    //JPG.SaveToFile('c:\desktop.jpg');
    application.ProcessMessages;
    Sleep(RefreshSeconds*1000);
  end;

  //TImg.picture.Bitmap.SaveToFile('c:\desktop.bmp');
end;


function TScreenSpy.ProcessSCNDC(Rate:double):HDC;
begin

  FWidth:= floor(GetSystemMetrics(SM_CXSCREEN)*Rate);
  FHeight:= floor(GetSystemMetrics(SM_CYSCREEN)*Rate);
  DCBMP.Width:= FWidth;
  DCBMP.Height:= FHeight;

  SetStretchBltMode(DCBMP.Canvas.Handle,STRETCH_HALFTONE);
  StretchBlt(DCBMP.Canvas.Handle,0,0,FWidth,FHeight,GetDC(0),0,0,GetSystemMetrics(SM_CXSCREEN),GetSystemMetrics(SM_CYSCREEN),SRCCOPY);
  result:=DCBMP.Canvas.Handle;

end;


procedure TScreenSpy.GetFirst;
var
  FullscreenCanvas:TCanvas;
begin
  FDC:=ProcessSCNDC(0.6);//���o�̹���DC�A�Ѽ�0�����O�̹�
  FullscreenCanvas:=TCanvas.Create;//�Ыؤ@��CANVAS�ﹳ
  FullscreenCanvas.Handle:=FDC;

  DCBMP.Canvas.CopyRect(Rect(0,0,FWidth,FHeight),fullscreenCanvas,Rect(0,0,FWidth,FHeight));
  //���ӫ̹��ƻs��BITMAP��
  FullscreenCanvas.Free;//����CANVAS�ﹳ
  //*******************************
  Server.Form1.Image1.picture.Bitmap.Assign(DCBMP);//�����U���Ϲ��ᵹIMAGE�ﹳ
  Server.Form1.Image1.picture.Bitmap.Width:=FWidth;
  Server.Form1.Image1.picture.Bitmap.Height:=FHeight;
end;





end.
