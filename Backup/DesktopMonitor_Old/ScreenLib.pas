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


//這個功能可以將 BMP / JPG 檔縮放到你指定的大小及品質的 JPG 格式，你可以將之存檔，存在數據庫，甚至放進 TStream 通過 ISAPI 直接傳給使用者 Browser 作為顯示圖檔。
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
  FDC:=ProcessSCNDC(0.6);//取得屏幕的DC，參數0指的是屏幕
  FullscreenCanvas:=TCanvas.Create;//創建一個CANVAS對像
  FullscreenCanvas.Handle:=FDC;

  DCBMP.Canvas.CopyRect(Rect(0,0,FWidth,FHeight),fullscreenCanvas,Rect(0,0,FWidth,FHeight));
  //把整個屏幕複製到BITMAP中
  FullscreenCanvas.Free;//釋放CANVAS對像
  //*******************************
  Server.Form1.Image1.picture.Bitmap.Assign(DCBMP);//拷貝下的圖像賦給IMAGE對像
  Server.Form1.Image1.picture.Bitmap.Width:=FWidth;
  Server.Form1.Image1.picture.Bitmap.Height:=FHeight;
end;





end.
