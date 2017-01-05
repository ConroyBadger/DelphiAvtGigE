unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, Vcl.Samples.Spin;

type
  TMainFrm = class(TForm)
    PaintBox: TPaintBox;
    Memo: TMemo;
    CamSettingsBtn: TBitBtn;
    DelayTimer: TTimer;
    SaveBtn: TBitBtn;
    SaveEdit: TSpinEdit;
    DeBayerCB: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure CamSettingsBtnClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DelayTimerTimer(Sender: TObject);
    procedure DeBayerCBClick(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);

  private
    procedure NewCameraFrame(Sender:TObject);
    procedure AssertSize;

  public

  end;

var
  MainFrm: TMainFrm;

implementation

{$R *.dfm}

uses
  PvCameraU, CamSettingsFrmU, BmpUtils;

procedure TMainFrm.FormCreate(Sender: TObject);
begin
  Camera:=TPvCamera.Create;
  Memo.Lines.Add(Camera.ApiStatusString);
  DelayTimer.Enabled:=True;
end;

procedure TMainFrm.FormDestroy(Sender: TObject);
begin
  Camera.Free;
end;

procedure TMainFrm.AssertSize;
const
  BORDER = 10;
var
  MinH : Integer;
begin
  if (PaintBox.Width<>Camera.ImageW) or (PaintBox.Height<>Camera.ImageH) then
  begin
    PaintBox.Width:=Camera.ImageW;
    PaintBox.Height:=Camera.ImageH;

    ClientWidth:=PaintBox.Left+PaintBox.Width+BORDER;
    ClientHeight:=PaintBox.Top+PaintBox.Height+Border;

    MinH:=SaveBtn.Top+SaveBtn.Height+BORDER;
    if ClientHeight<MinH then ClientHeight:=MinH;
  end;
end;

procedure TMainFrm.NewCameraFrame(Sender:TObject);
begin
  AssertSize;

  ShowFrameRateOnBmp(Camera.Bmp,Camera.MeasuredFPS);
  PaintBox.Canvas.Draw(0,0,Camera.Bmp);
end;

procedure TMainFrm.DelayTimerTimer(Sender: TObject);
begin
  DelayTimer.Enabled:=False;
  Camera.ShowDevicesInLines(Memo.Lines);
  Camera.UseFirstDevice;
  Camera.ShowInfoInLines(Memo.Lines);
  Camera.Start;
  Camera.OnNewFrame:=NewCameraFrame;
end;

procedure TMainFrm.CamSettingsBtnClick(Sender: TObject);
begin
  CamSettingsFrm:=TCamSettingsFrm.Create(Application);
  try
    CamSettingsFrm.Initialize;
    CamSettingsFrm.ShowModal;
  finally
    CamSettingsFrm.Free;
  end;
end;

procedure TMainFrm.DeBayerCBClick(Sender: TObject);
begin
  Camera.DeBayer:=DeBayerCB.Checked;
end;

function Path:String;
begin
  Result:=ExtractFilePath(Application.ExeName);
end;

procedure TMainFrm.SaveBtnClick(Sender: TObject);
var
  FileName : String;
  I        : Integer;
begin
  I:=Round(SaveEdit.Value);
  FileName:=Path+'Bmp'+IntToStr(I)+'.bmp';
  Camera.Bmp.SaveToFile(FileName);
  SaveEdit.Value:=I+1;
  ShowMessage('Image saved as '+FileName);
end;

end.


