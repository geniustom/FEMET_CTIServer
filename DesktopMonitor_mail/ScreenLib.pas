unit ScreenLib;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, MemDS, DBAccess, Ora,IdMessage, IdTCPConnection, IdTCPClient,
  IdMessageClient, IdSMTP, IdBaseComponent, IdComponent, IdIOHandler,
  IdIOHandlerSocket, IdSSLOpenSSL, StdCtrls,ExtCtrls, ADODB,jpeg,math,pngimage;

type


  TScreenSpy = class(TThread)
  private
    FDC: HDC;
    DCBMP:TBitmap;
    TImg:Timage;
    RefreshSeconds:integer;
    FPixelFormat: TPixelFormat;
    //
    function ProcessSCNDC(Rate:double):HDC;
  protected
    procedure Execute; override;
  public
    FWidth, FHeight,FSize: Integer;
    NeedRefresh:boolean;
    constructor Create(var IMG:Timage;RefreshTime:integer); reintroduce;
    destructor Destroy; override;
    //
    property PixelFormat: TPixelFormat read FPixelFormat write FPixelFormat;
    procedure GetFirst;
  end;


implementation


constructor TScreenSpy.Create(var IMG:Timage;RefreshTime:integer);
begin
  FreeOnTerminate := True;

  FPixelFormat := pf24bit;
  DCBMP := TBitmap.Create;
  DCBmp.Width  := FWidth;
  DCBmp.Height := FHeight;
  DCBmp.PixelFormat := FPixelFormat;
  TImg:=IMG;
  RefreshSeconds:=RefreshTime;
  NeedRefresh:=false;
  inherited Create(True);
end;

destructor TScreenSpy.Destroy;
var
  i: Integer;
begin
  DCBMP.Free;
  inherited;
end;


procedure TScreenSpy.Execute;
var
JPG:TJpegImage;
APng: TPngObject;
begin
  while (not Terminated)  do
  begin
    try
      if NeedRefresh=false then
      begin
        GetFirst;
      end;
    except
    end;
    APng:=TPngObject.Create;
    APng.Assign(TImg.Picture.Bitmap);
    APng.SaveToFile('c:\desktop.png');
    NeedRefresh:=true;
    Sleep(RefreshSeconds*1000);
  end;

end;


function TScreenSpy.ProcessSCNDC(Rate:double):HDC;
var
Nw,Nh:integer;
begin
  //result:=GetDC(0);
  FWidth:= floor(GetSystemMetrics(SM_CXSCREEN)*Rate);
  FHeight:= floor(GetSystemMetrics(SM_CYSCREEN)*Rate);

  DCBmp.Width  := FWidth;
  DCBmp.Height := FHeight;
  SetStretchBltMode(DCBMP.Canvas.Handle,STRETCH_HALFTONE);
  StretchBlt(DCBMP.Canvas.Handle,0,0,FWidth,FHeight,GetDC(0),0,0,GetSystemMetrics(SM_CXSCREEN),GetSystemMetrics(SM_CYSCREEN),SRCCOPY);
  result:=DCBMP.Canvas.Handle;
end;




procedure TScreenSpy.GetFirst;
var
  FullscreenCanvas:TCanvas;
begin
  FDC:=ProcessSCNDC(0.8);//取得屏幕的DC，參數0指的是屏幕
  FullscreenCanvas:=TCanvas.Create;//創建一個CANVAS對像
  FullscreenCanvas.Handle:=FDC;

  DCBMP.Canvas.CopyRect(Rect(0,0,FWidth,FHeight),fullscreenCanvas,Rect(0,0,FWidth,FHeight));
  //把整個屏幕複製到BITMAP中
  FullscreenCanvas.Free;//釋放CANVAS對像
  //*******************************
  TImg.picture.Bitmap:=DCBMP;//拷貝下的圖像賦給IMAGE對像
  TImg.Width:=FWidth;
  TImg.Height:=FHeight;
end;







end.
