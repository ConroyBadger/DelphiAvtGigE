object CamSettingsFrm: TCamSettingsFrm
  Left = 1947
  Top = 290
  BorderStyle = bsDialog
  Caption = 'Camera settings'
  ClientHeight = 227
  ClientWidth = 330
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = False
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 153
    Height = 57
    Color = 14141894
    TabOrder = 0
    object Label1: TLabel
      Left = 1
      Top = 1
      Width = 151
      Height = 14
      Align = alTop
      Alignment = taCenter
      AutoSize = False
      Caption = 'Exposure'
      Color = 13869224
      ParentColor = False
      Transparent = False
    end
    object ExposureEdit: TSpinEdit
      Left = 10
      Top = 24
      Width = 135
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 0
      Value = 50
    end
  end
  object Panel2: TPanel
    Left = 168
    Top = 8
    Width = 153
    Height = 57
    Color = 14141894
    TabOrder = 1
    object Label2: TLabel
      Left = 1
      Top = 1
      Width = 151
      Height = 14
      Align = alTop
      Alignment = taCenter
      AutoSize = False
      Caption = 'Gain'
      Color = 13869224
      ParentColor = False
      Transparent = False
    end
    object GainEdit: TSpinEdit
      Left = 8
      Top = 24
      Width = 136
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 0
      Value = 50
    end
  end
  object Panel3: TPanel
    Left = 8
    Top = 72
    Width = 153
    Height = 98
    Color = 14141894
    TabOrder = 2
    object Label5: TLabel
      Left = 1
      Top = 1
      Width = 151
      Height = 14
      Align = alTop
      Alignment = taCenter
      AutoSize = False
      Caption = 'White balance'
      Color = 13869224
      ParentColor = False
      Transparent = False
    end
    object WhiteBalanceRedEdit: TSpinEdit
      Left = 41
      Top = 44
      Width = 75
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 0
      Value = 100
    end
    object WhiteBalanceBlueEdit: TSpinEdit
      Left = 41
      Top = 69
      Width = 75
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 2
      Value = 100
    end
    object WhiteBalanceRateEdit: TSpinEdit
      Left = 90
      Top = 19
      Width = 53
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 3
      Value = 100
      OnExit = WhiteBalanceRateEditExit
    end
    object AutoWhiteBalanceCB: TCheckBox
      Left = 13
      Top = 21
      Width = 76
      Height = 17
      Caption = 'Auto   Rate:'
      TabOrder = 1
      OnClick = AutoWhiteBalanceCBClick
    end
  end
  object Panel4: TPanel
    Left = 169
    Top = 71
    Width = 153
    Height = 98
    Color = 14141894
    TabOrder = 3
    object Label6: TLabel
      Left = 1
      Top = 1
      Width = 151
      Height = 14
      Align = alTop
      Alignment = taCenter
      AutoSize = False
      Caption = 'Network settings'
      Color = 13869224
      ParentColor = False
      Transparent = False
    end
    object Label3: TLabel
      Left = 14
      Top = 46
      Width = 58
      Height = 13
      Caption = 'Packet size:'
    end
    object Label4: TLabel
      Left = 8
      Top = 73
      Width = 65
      Height = 13
      Caption = 'Stream MB/s:'
    end
    object PacketSizeEdit: TSpinEdit
      Left = 78
      Top = 42
      Width = 60
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 0
      Value = 1500
      OnChange = PacketSizeEditChange
    end
    object StreamBytesPerSecondEdit: TSpinEdit
      Left = 78
      Top = 69
      Width = 60
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 1
      Value = 32
      OnChange = StreamBytesPerSecondEditChange
    end
    object MulticastCB: TCheckBox
      Left = 21
      Top = 23
      Width = 97
      Height = 17
      Caption = 'Multicast'
      TabOrder = 2
      OnClick = MulticastCBClick
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 208
    Width = 330
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object FlipImageCB: TCheckBox
    Left = 8
    Top = 180
    Width = 70
    Height = 17
    Caption = 'Flip image'
    TabOrder = 5
    OnClick = FlipImageCBClick
  end
  object MirrorCB: TCheckBox
    Left = 98
    Top = 180
    Width = 79
    Height = 17
    Caption = 'Mirror image'
    TabOrder = 6
    OnClick = MirrorCBClick
  end
  object Timer: TTimer
    Enabled = False
    Interval = 50
    OnTimer = TimerTimer
    Left = 216
    Top = 152
  end
end
