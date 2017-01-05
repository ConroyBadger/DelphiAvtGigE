unit CamSettingsFrmU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Vcl.ComCtrls, Vcl.Samples.Spin;

type
  TCamSettingsFrm = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Panel2: TPanel;
    Label2: TLabel;
    Panel3: TPanel;
    Label5: TLabel;
    Panel4: TPanel;
    Label6: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    StatusBar: TStatusBar;
    Timer: TTimer;
    ExposureEdit: TSpinEdit;
    GainEdit: TSpinEdit;
    WhiteBalanceRedEdit: TSpinEdit;
    WhiteBalanceBlueEdit: TSpinEdit;
    WhiteBalanceRateEdit: TSpinEdit;
    PacketSizeEdit: TSpinEdit;
    StreamBytesPerSecondEdit: TSpinEdit;
    AutoWhiteBalanceCB: TCheckBox;
    MulticastCB: TCheckBox;
    FlipImageCB: TCheckBox;
    MirrorCB: TCheckBox;
    procedure ExposureEditValueChange(Sender: TObject);
    procedure GainEditValueChange(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure PacketSizeEditChange(Sender: TObject);
    procedure StreamBytesPerSecondEditChange(Sender: TObject);
    procedure MulticastCBClick(Sender: TObject);
    procedure AutoWhiteBalanceCBClick(Sender: TObject);
    procedure WhiteBalanceRedEditValueChange(Sender: TObject);
    procedure WhiteBalanceBlueEditValueChange(Sender: TObject);
    procedure WhiteBalanceRateEditExit(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FlipImageCBClick(Sender: TObject);
    procedure MirrorCBClick(Sender: TObject);

  private

  public
    procedure Initialize;
  end;

var
  CamSettingsFrm: TCamSettingsFrm;

implementation

{$R *.dfm}

uses
  PvCameraU;

procedure TCamSettingsFrm.Initialize;
begin
  Camera.ReadExposure;
  ExposureEdit.MinValue:=Camera.Exposure.Min;
  ExposureEdit.MaxValue:=Camera.Exposure.Max;
  ExposureEdit.Value:=Camera.Exposure.Value;

  Camera.ReadGain;
  GainEdit.MinValue:=Camera.Gain.Min;
  GainEdit.MaxValue:=Camera.Gain.Max;
  GainEdit.Value:=Camera.Gain.Value;

  AutoWhiteBalanceCB.Checked:=(Camera.GetWhiteBalanceMode=AutoMode);
  WhiteBalanceRateEdit.Value:=Camera.GetWhiteBalanceRate;
  WhiteBalanceRedEdit.Value:=Camera.GetWhiteBalanceRed;
  WhiteBalanceBlueEdit.Value:=Camera.GetWhiteBalanceBlue;

  MultiCastCB.Checked:=Camera.Multicast;
  PacketSizeEdit.Value:=Camera.PacketSize;
  StreamBytesPerSecondEdit.Value:=Round(Camera.StreamBytesPerSecond/1000000);

  FlipImageCB.Checked:=Camera.FlipImage;
  MirrorCB.Checked:=Camera.MirrorImage;

  Timer.Enabled:=True;
end;

procedure TCamSettingsFrm.ExposureEditValueChange(Sender: TObject);
begin
  Camera.SetExposure(Round(ExposureEdit.Value));
end;

procedure TCamSettingsFrm.GainEditValueChange(Sender: TObject);
begin
  Camera.SetGain(Round(GainEdit.Value));
end;

procedure TCamSettingsFrm.FlipImageCBClick(Sender: TObject);
begin
  Camera.FlipImage:=FlipImageCB.Checked;
end;

procedure TCamSettingsFrm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then Perform(WM_NEXTDLGCTL,0,0)
  else if Key=#27 then Close;
end;

procedure TCamSettingsFrm.PacketSizeEditChange(Sender: TObject);
begin
  Camera.PacketSize:=Round(PacketSizeEdit.Value);
end;

procedure TCamSettingsFrm.StreamBytesPerSecondEditChange(Sender: TObject);
begin
  Camera.StreamBytesPerSecond:=Round(StreamBytesPerSecondEdit.Value*1000000);
end;

procedure TCamSettingsFrm.TimerTimer(Sender: TObject);
begin
  WhiteBalanceRedEdit.Value:=Camera.GetWhiteBalanceRed;
  WhiteBalanceBlueEdit.Value:=Camera.GetWhiteBalanceBlue;

  StatusBar.SimpleText:='Frames: '+IntToStr(Camera.FrameCount);
end;

procedure TCamSettingsFrm.MirrorCBClick(Sender: TObject);
begin
  Camera.MirrorImage:=MirrorCB.Checked;
end;

procedure TCamSettingsFrm.MulticastCBClick(Sender: TObject);
begin
  Camera.MultiCast:=MultiCastCB.Checked;
end;

procedure TCamSettingsFrm.AutoWhiteBalanceCBClick(Sender: TObject);
begin
  if AutoWhiteBalanceCB.Checked then Camera.SetWhiteBalanceMode(AutoMode)
  else Camera.SetWhiteBalanceMode(ManualMode);
end;

procedure TCamSettingsFrm.WhiteBalanceRedEditValueChange(Sender: TObject);
begin
  Camera.SetWhiteBalanceRed(Round(WhiteBalanceRedEdit.Value));
end;

procedure TCamSettingsFrm.WhiteBalanceBlueEditValueChange(Sender: TObject);
begin
  Camera.SetWhiteBalanceBlue(Round(WhiteBalanceBlueEdit.Value));
end;

procedure TCamSettingsFrm.WhiteBalanceRateEditExit(Sender: TObject);
begin
  Camera.SetWhiteBalanceRate(Round(WhiteBalanceRateEdit.Value));
end;

end.
