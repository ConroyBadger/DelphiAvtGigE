object MainFrm: TMainFrm
  Left = 968
  Top = 195
  ClientHeight = 514
  ClientWidth = 939
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBox: TPaintBox
    Left = 239
    Top = 10
    Width = 694
    Height = 496
  end
  object Memo: TMemo
    Left = 8
    Top = 8
    Width = 225
    Height = 379
    TabOrder = 0
  end
  object CamSettingsBtn: TBitBtn
    Left = 24
    Top = 394
    Width = 75
    Height = 25
    Caption = 'Settings'
    TabOrder = 1
    OnClick = CamSettingsBtnClick
  end
  object SaveBtn: TBitBtn
    Left = 20
    Top = 459
    Width = 75
    Height = 23
    Caption = 'Save as #'
    TabOrder = 3
    OnClick = SaveBtnClick
  end
  object SaveEdit: TSpinEdit
    Left = 104
    Top = 460
    Width = 48
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 4
    Value = 1
  end
  object DeBayerCB: TCheckBox
    Left = 32
    Top = 426
    Width = 73
    Height = 17
    Caption = 'Debayer'
    TabOrder = 2
    OnClick = DeBayerCBClick
  end
  object DelayTimer: TTimer
    Enabled = False
    Interval = 100
    OnTimer = DelayTimerTimer
    Left = 32
    Top = 32
  end
end
