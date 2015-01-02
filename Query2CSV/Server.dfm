object Form1: TForm1
  Left = 192
  Top = 127
  Width = 244
  Height = 175
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 228
    Height = 137
    Align = alClient
    TabOrder = 0
  end
  object OraSession1: TOraSession
    ConnectPrompt = False
    Options.Net = True
    Left = 63
    Top = 9
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
  object OraQuery1: TOraQuery
    Session = OraSession1
    Left = 30
    Top = 9
  end
  object ADO: TADOConnection
    ConnectionString = 
      'Provider=SQLOLEDB.1;Persist Security Info=False;User ID=sa;Initi' +
      'al Catalog=CallCenter;Data Source=61.218.115.194,1435'
    Provider = 'SQLOLEDB.1'
    Left = 30
    Top = 66
  end
  object ADOQ: TADOQuery
    Connection = ADO
    Parameters = <>
    Left = 63
    Top = 66
  end
end
