object Form1: TForm1
  Left = 258
  Top = 129
  BorderStyle = bsSingle
  Caption = #34722#24149#25847#21462#31243#24335
  ClientHeight = 242
  ClientWidth = 429
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMinimized
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 151
    Top = 0
    Width = 278
    Height = 242
    Align = alClient
  end
  object Splitter1: TSplitter
    Left = 148
    Top = 0
    Height = 242
  end
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 148
    Height = 242
    Align = alLeft
    TabOrder = 0
  end
  object Button1: TButton
    Left = 3
    Top = 216
    Width = 142
    Height = 25
    Caption = 'Button1'
    TabOrder = 1
  end
  object IdSMTP1: TIdSMTP
    MaxLineAction = maException
    ReadTimeout = 0
    Port = 25
    AuthenticationType = atNone
    Left = 120
    Top = 15
  end
  object IdMessage1: TIdMessage
    AttachmentEncoding = 'MIME'
    BccList = <>
    CCList = <>
    Encoding = meMIME
    Recipients = <>
    ReplyTo = <>
    Left = 150
    Top = 15
  end
  object IdSSLIOHandlerSocket1: TIdSSLIOHandlerSocket
    SSLOptions.Method = sslvSSLv2
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    Left = 180
    Top = 15
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 213
    Top = 15
  end
end
