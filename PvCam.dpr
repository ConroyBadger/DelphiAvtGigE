program PvCam;



uses
  Forms,
  Main in 'Main.pas' {MainFrm},
  PvCameraU in 'PvCameraU.pas',
  PvApi in 'PvApi.pas',
  CamSettingsFrmU in 'CamSettingsFrmU.pas',
  BmpUtils in 'BmpUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.Run;
end.
