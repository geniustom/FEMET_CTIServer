object Form1: TForm1
  Left = 192
  Top = 127
  Width = 248
  Height = 178
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object CTI_SQL: TADOConnection
    CommandTimeout = 5
    ConnectionTimeout = 5
    IsolationLevel = ilIsolated
    LoginPrompt = False
    Provider = 'SQLOLEDB'
    Left = 21
    Top = 12
  end
  object CTIQuery: TADOQuery
    Connection = CTI_SQL
    CursorType = ctStatic
    Parameters = <>
    Left = 54
    Top = 12
  end
  object DataQuery: TADOQuery
    Connection = CTI_SQL
    CursorType = ctStatic
    Parameters = <>
    Left = 84
    Top = 12
  end
end
