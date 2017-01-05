unit PvCameraU;

interface

uses
  Windows, PvApi, SysUtils, Classes, Graphics, Forms, Dialogs;

const
  MaxImageW = 659;
  MaxImageH = 493;
  FrameSize = MaxImageW*MaxImageH;
  MaxFrames = 15;

  ManualMode   = 0;
  AutoMode     = 1;
  AutoOnceMode = 2;
  ExternalMode = 3;

  MinGain = 0;
  MaxGain = 22;

  FrameRate = 15;

  FrameRateAverages  = 10;

type
  TCameraWindow = record
    X,Y,W,H : DWord;
  end;

  TWhiteBalance = record
    Mode : Integer;
    Red  : DWord;
    Blue : DWord;
    Rate : DWord;
  end;

  TExposure = record
    Mode                : String[255];
    Value               : DWord;  // microseconds
    AutoAdjustDelay     : DWord; // delay before making any adjustments
    AutoAdjustTolerance : DWord;
    AutoAlgoritm        : Integer; // 0=mean, 1=FitRange
    Min,Max             : DWord;
  end;

  TGain = record
    Min   : DWord; // 0
    Max   : DWord; // 22
    Value : DWord; // no units
  end;

  TFrameData      = array[1..FrameSize] of Byte;
  TFrameDataArray = array[1..MaxFrames] of TFrameData;

  TPvFrameArray = array[1..MaxFrames] of TPvFrame;

  TPvCamera = class(TObject)
  private
    Frame       : TPvFrameArray;
    FrameData   : TFrameDataArray;
    FrameI      : Integer;
    PvStatus    : Integer;
    FOnNewFrame : TNotifyEvent;

    FrameRateFrame : Integer;
    LastFPSTime    : DWord;

    procedure CallBack(iFrame:PPvFrame); stdcall;
    procedure AddEnumsToStrings(Param:String;Strings:TStrings);

    function  GetMultiCast : Boolean;
    procedure SetMultiCast(Value:Boolean);

    function  GetStreamBytesPerSecond:DWord;
    procedure SetStreamBytesPerSecond(Value:DWord);

    function  GetPacketSize:DWord;
    procedure SetPacketSize(Size:DWord);

    procedure SizeBmpAndFrames;
    procedure SetWindow(NewWindow: TCameraWindow);

    function LinePaddingForXSize(Size:Integer):Integer;
    procedure MeasureFPS(iFrame: PPvFrame);

  public
    HCamera      : Pointer;
    Bmp          : TBitmap;
    Running      : Boolean;
    ImageW       : Integer;
    ImageH       : Integer;
    Gain         : TGain;
    Exposure     : TExposure;
    WhiteBalance : TWhiteBalance;
    DeBayer      : Boolean;
    Window       : TCameraWindow;
    FlipImage    : Boolean;
    MirrorImage  : Boolean;
    FrameCount   : Integer;
    MeasuredFPS  : Single;

    property OnNewFrame:TNotifyEvent read FOnNewFrame write FOnNewFrame;

    property MultiCast : Boolean read GetMultiCast write SetMultiCast;

    property StreamBytesPerSecond : DWord read GetStreamBytesPerSecond
                                    write SetStreamBytesPerSecond;

    property PacketSize : DWord read GetPacketSize write SetPacketSize;



    constructor Create;
    destructor  Destroy; override;

    function  ApiVersionString:String;
    function  CameraCount:Integer;
    procedure ShowDevicesInLines(Lines:TStrings);
    procedure UseFirstDevice;
    procedure Start;
    procedure Stop;

    function  AbleToGetDWordParameter(Param:String;var V:DWord):Boolean;
    function  AbleToSetDWordParameter(Param:String;var V:DWord):Boolean;

    procedure ShowInfoInLines(Lines:TStrings);
    function  ApiStatusString:String;

    procedure ReadGain;
    procedure ReadExposure;

    procedure FillExposureModeStrings(Strings:TStrings);
    procedure ShowSettingsFrm;
    procedure SetExposureMode(Mode:String);
    procedure SetExposure(V:DWord);
    procedure SetGain(V:DWord);
    procedure DeBayerFrame(var iFrame:TPvFrame);

    function AbleToGetEnumParameter(Param,Value:String):Boolean;
    function AbleToSetEnumParameter(Param,Value:String):Boolean;

    function  GetWhiteBalanceMode: Integer;
    procedure SetWhiteBalanceMode(Mode: Integer);

    function  GetWhiteBalanceRed:DWord;
    procedure SetWhiteBalanceRed(Value:DWord);

    function  GetWhiteBalanceBlue:DWord;
    procedure SetWhiteBalanceBlue(Value:DWord);

    function  GetWhiteBalanceRate:DWord;
    procedure SetWhiteBalanceRate(Rate:DWord);
    function  ModeToString(Mode:Integer): String;

    procedure PickBestPacketSize(Max:DWord);
    procedure SetPvBinning(V: DWord);
  end;

var
  Camera : TPvCamera;

implementation

uses
  CamSettingsFrmU;

procedure DrawFrameOnBmp(var Frame:TPvFrame;Bmp:TBitmap);
var
  BytePtr : PByte;
  X,Y,I   : Integer;
  Line    : PByteArray;
  LineSize : Integer;
begin
  Bmp.Width:=Frame.Width;
  Bmp.Height:=Frame.Height;
  LineSize:=Frame.Width*3;

  BytePtr:=PByte(Frame.ImageBuffer);
  for Y:=0 to Frame.Height-1 do begin
    Line:=Bmp.ScanLine[Y];
    I:=0;
    for X:=0 to Frame.Width-1 do begin
      Line^[I+0]:=BytePtr^;
      Line^[I+1]:=BytePtr^;
      Line^[I+2]:=BytePtr^;
      Inc(BytePtr);
      Inc(I,3);
    end;
  end;
end;

procedure FrameCallBack(iFrame:PPvFrame); stdcall;
begin
  Camera.CallBack(iFrame);
end;

procedure TPvCamera.MeasureFPS(iFrame:PPvFrame);
var
  Time        : DWord;
  ElapsedTime : Single;
begin
  Inc(FrameCount);
  if (FrameCount-FrameRateFrame)>=FrameRateAverages then begin
    Time:=GetTickCount;
    ElapsedTime:=(Time-LastFPSTime)/1000;
    if ElapsedTime=0 then MeasuredFPS:=0
    else MeasuredFPS:=FrameRateAverages/ElapsedTime;
    LastFPSTime:=Time;

    FrameRateFrame:=FrameCount;
  end;
end;

procedure TPvCamera.CallBack(iFrame:PPvFrame); stdcall;
begin
  if Assigned(iFrame) then begin
    ImageW:=iFrame.Width;
    ImageH:=iFrame.Height;

    Bmp.Width:=Camera.ImageW;
    Bmp.Width:=Camera.ImageW;

    if DeBayer then DeBayerFrame(iFrame^)
    else DrawFrameOnBmp(iFrame^,Bmp);

    MeasureFPS(iFrame);

    if FrameI<MaxFrames then Inc(FrameI)
    else FrameI:=1;
    PvCaptureQueueFrame(HCamera,Frame[FrameI],@FrameCallBack);
    if Assigned(FOnNewFrame) then FOnNewFrame(Self);
  end;
end;

constructor TPvCamera.Create;
var
  F : Integer;
begin
  inherited Create;

// init vars
  HCamera:=nil;
  DeBayer:=False;

  FlipImage:=False;
  MirrorImage:=False;

  FrameI:=0;
  for F:=1 to MaxFrames do begin
    Frame[F].ImageBuffer:=@FrameData[F];
    Frame[F].AncillaryBufferSize:=0;
    Frame[F].Width:=MaxImageW;
    Frame[F].Height:=MaxImageH;
    Frame[F].ImageBufferSize:=FrameSize;
    Frame[F].Format:=ePvFmtBayer8;
    Frame[F].RegionX:=0;
    Frame[F].RegionY:=0;
    Frame[F].BitDepth:=8;
  end;
  FOnNewFrame:=nil;
  Running:=False;

  Bmp:=TBitmap.Create;
  Bmp.PixelFormat:=pf24Bit;
  Bmp.Width:=MaxImageW;
  Bmp.Height:=MaxImageH;

// init the api
  PvStatus:=PvInitialize;

// add time for sending discovery packets and receiving acknowledges
  Sleep(300);
end;

destructor TPvCamera.Destroy;
begin
// close the camera
  if Assigned(HCamera) then begin
    if Running then Stop;
    PvCameraClose(HCamera);
  end;

// shut down the API
  if PvStatus=ePvErrSuccess then PvUnInitialize;

  inherited Destroy;
end;

function TPvCamera.ApiVersionString:String;
var
  Major,Minor : DWord;
begin
  PvVersion(Major,Minor);
  Result:='API version '+IntToStr(Major)+'.'+IntToStr(Minor);
end;

function TPvCamera.CameraCount:Integer;
begin
  Result:=PvCameraCount;
end;

procedure TPvCamera.ShowDevicesInLines(Lines:TStrings);
var
  CameraInfo : TPvCameraInfoArray;
  Count      : DWord;
  Found      : DWord;
  I          : Integer;
begin
  Count:=PvCameraList(@CameraInfo[1],MaxCameras,Found);
  Lines.Add('');
  if Found=1 then Lines.Add('1 camera found')
  else Lines.Add(IntToStr(Found)+' cameras found');
  for I:=1 to Count do begin
    Lines.Add('Camera #'+IntToStr(I)+' ID = '+IntToStr(CameraInfo[I].UniqueId));
  end;
end;

procedure TPvCamera.UseFirstDevice;
var
  CameraInfo : TPvCameraInfoArray;
  Count      : DWord;
  Found      : DWord;
  RC         : Integer;
begin
  Count:=PvCameraList(@CameraInfo[1],1,Found);
  if (Count>0) and (Found>0) then begin
    RC:=PvCameraOpen(CameraInfo[1].UniqueID,ePvAccessMaster,HCamera);
    if RC<>ePvErrSuccess then HCamera:=nil;
  end;
end;

procedure TPvCamera.ShowInfoInLines(Lines:TStrings);
var
  V : DWord;
begin
  if Lines.Count>0 then Lines.Add('');

  if AbleToGetDWordParameter('TotalBytesPerFrame',V) then begin
    Lines.Add('Bytes per frame: '+IntToStr(V))
  end
  else Lines.Add('Error gettings bytes per frame');

  if AbleToGetDWordParameter('SensorWidth',V) then begin
    Lines.Add('Sensor width: '+IntToStr(V));
  end
  else Lines.Add('Error getting sensor width');

  if AbleToGetDWordParameter('SensorHeight',V) then begin
    Lines.Add('Sensor height: '+IntToStr(V));
  end
  else Lines.Add('Error getting sensor height');
end;

function TPvCamera.AbleToGetDWordParameter(Param:String;var V:DWord):Boolean;
begin
  Result:=Assigned(HCamera) and
         (PvAttrUint32Get(HCamera,PChar(Param),V)=ePvErrSuccess);
end;

function TPvCamera.AbleToSetDWordParameter(Param:String;var V:DWord):Boolean;
begin
  Result:=Assigned(HCamera) and
         (PvAttrUint32Set(HCamera,PChar(Param),V)=ePvErrSuccess);
end;

function TPvCamera.AbleToGetEnumParameter(Param,Value:String):Boolean;
const
  MaxSize = 255;
var
  Size : DWord;
begin
  Result:=False;
  if Assigned(HCamera) then begin
    SetLength(Value,MaxSize);
    if PvAttrEnumGet(HCamera,PChar(Param),@Value[1],MaxSize,Size)=ePvErrSuccess
    then begin
      SetLength(Value,Size);
    end;
  end;
end;

function TPvCamera.AbleToSetEnumParameter(Param,Value:String):Boolean;
begin
  Result:=False;
  if Assigned(HCamera) then begin
    Result:=PvAttrEnumSet(HCamera,PChar(Param),PChar(Value))=ePvErrSuccess;
  end;
end;

procedure TPvCamera.Start;
var
  FSize : DWord;
  F,RC  : Integer;
begin
  if Assigned(HCamera) then begin
    RC:=PvCaptureStart(HCamera);
    if RC=ePvErrSuccess then begin
      PvAttrEnumSet(HCamera,'AcquisitionMode','Continuous');
      PvCommandRun(HCamera,'AcquisitionStart');
      if AbleToGetDWordParameter('TotalBytesPerFrame',FSize) then begin
        FrameI:=1;
        for F:=1 to MaxFrames do Frame[F].ImageBufferSize:=FSize;
        PvCaptureQueueFrame(HCamera,Frame[1],@FrameCallBack);
        Running:=True;
      end;
    end
    else PvCaptureEnd(HCamera);
  end;
end;

procedure TPvCamera.Stop;
begin
  if Assigned(HCamera) then begin
    PvCaptureEnd(HCamera);
    Running:=False;
  end;
end;

function TPvCamera.ApiStatusString:String;
begin
  Case PvStatus of
    ePvErrSuccess       : Result:='Pv DLL version '+ApiVersionString+' initialized';
    ePvErrResources     : Result:='Out of resources';
    ePvErrInternalFault : Result:='Driver error';
    else Result:='???';
  end;
end;

procedure TPvCamera.ReadGain;
begin
  Gain.Min:=MinGain;
  Gain.Max:=MaxGain;
  AbleToGetDWordParameter('GainValue',Gain.Value);
end;

procedure TPvCamera.ReadExposure;
begin
  AbleToGetEnumParameter('ExposureMode',Exposure.Mode);
  Exposure.Min:=0;
  Exposure.Max:=Round(1000000/FrameRate);
  AbleToGetDWordParameter('ExposureValue',Exposure.Value);
end;

procedure TPvCamera.AddEnumsToStrings(Param:String;Strings:TStrings);
const
  MaxSize = 1024;
var
  RC,I,I1 : Integer;
  I2      : Integer;
  Buffer  : array[1..MaxSize] of Char;
  SubStr  : String;
  Size    : DWord;
begin
  Strings.Clear;
  if Assigned(HCamera) then begin
    RC:=pvAttrRangeEnum(HCamera,PChar(Param),@Buffer[1],MaxSize,Size);
    I1:=1;
    for I:=1 to Size do begin
      if Buffer[I]=',' then begin
        SubStr:='';
        for I2:=I1 to I-1 do SubStr:=SubStr+Buffer[I2];
        I1:=I+1;
        Strings.Add(SubStr);
      end;
    end;
  end;
end;

procedure TPvCamera.FillExposureModeStrings(Strings:TStrings);
begin
  AddEnumsToStrings('ExposureMode',Strings);
end;

procedure TPvCamera.ShowSettingsFrm;
begin
  CamSettingsFrm:=TCamSettingsFrm.Create(Application);
  try
    CamSettingsFrm.Initialize;
    CamSettingsFrm.ShowModal;
  finally
    CamSettingsFrm.Free;
  end;
end;

procedure TPvCamera.SizeBmpAndFrames;
var
  F,W,H : DWord;
  Size  : DWord;
begin
  PvCaptureQueueClear(HCamera);
  if AbleToGetDWordParameter('Width',W) and
     AbleToGetDWordParameter('Height',H) then
  begin
    ImageW:=W;
    ImageH:=H;
    Bmp.Width:=W;
    Bmp.Height:=H;
    if AbleToGetDWordParameter('FrameSize',Size) then begin
      for F:=1 to MaxFrames do begin
        Frame[F].Width:=W;
        Frame[F].Height:=H;
        Frame[F].ImageBufferSize:=Size;
      end;
    end;
  end;
  for F:=1 to MaxFrames do begin
    PvCaptureQueueFrame(HCamera,Frame[F],@FrameCallBack);
  end;
end;

procedure TPvCamera.SetExposureMode(Mode:String);
begin
  AbleToSetEnumParameter('ExposureMode',Mode);
end;

procedure TPvCamera.SetExposure(V:DWord);
begin
  AbleToSetDWordParameter('ExposureValue',V);
end;

procedure TPvCamera.SetGain(V:DWord);
begin
  AbleToSetDWordParameter('GainValue',V);
end;

function Padding(X:Integer):Integer;
begin
  Result:=(X+3) and $FFFC;
  Result:=Result-X;
  Result:=((X+3) and $FFFC)-X;
end;

function TPvCamera.LinePaddingForXSize(Size:Integer):Integer;
begin
  Result:=((Size+3) and (not 3))-Size;
end;

procedure TPvCamera.DeBayerFrame(var iFrame:TPvFrame);
var
  LinePadding : DWord;
  LineSize    : DWord;
  BufferSize  : DWord;
  Buffer      : PByteArray;
  BufferPtr   : PByte;
  I,X,Y       : Integer;
  Line        : PByteArray;
begin
  LinePadding:=LinePaddingForXSize(iFrame.Width*3);

  LineSize:=(iFrame.Width*3)+LinePadding;

  BufferSize:=LineSize*iFrame.Height;
  GetMem(Buffer,BufferSize);
  try
    Assert(iFrame.Format=ePvFmtBayer8,'');
    PvUtilityColorInterpolate(@iFrame,@Buffer[2],@Buffer[1],@Buffer[0],2,LinePadding);
    BufferPtr:=PByte(@Buffer[0]);

    if FlipImage then for Y:=iFrame.Height-1 downto 0 do begin
      Line:=Bmp.ScanLine[Y];
      if MirrorImage then begin
        for X:=iFrame.Width-1 downto 0 do begin
          I:=X*3;
          Line^[I]:=BufferPtr^;
          Inc(BufferPtr);
          Line^[I+1]:=BufferPtr^;
          Inc(BufferPtr);
          Line^[I+2]:=BufferPtr^;
          Inc(BufferPtr);
        end;
        Inc(BufferPtr,LinePadding);
      end
      else begin
        Move(BufferPtr^,Line^,LineSize);
        Inc(BufferPtr,LineSize);
      end;
    end
    else for Y:=0 to iFrame.Height-1 do begin
      Line:=Bmp.ScanLine[Y];
      Move(BufferPtr^,Line^,LineSize);
      Inc(BufferPtr,LineSize);
    end;
  finally
    FreeMem(Buffer);
  end;
end;


function TPvCamera.GetWhiteBalanceMode:Integer;
var
  ModeStr : String;
begin
  AbleToGetEnumParameter('WhitebalMode',ModeStr);
  if ModeStr='Auto' then Result:=AutoMode
  else Result:=ManualMode;
end;

procedure TPvCamera.SetWhiteBalanceMode(Mode:Integer);
var
  ModeStr : String;
begin
  WhiteBalance.Mode:=Mode;
  ModeStr:=ModeToString(Mode);
  AbleToSetEnumParameter('WhitebalMode',ModeStr);
end;

function TPvCamera.GetWhiteBalanceRed:DWord;
begin
  if not AbleToGetDWordParameter('WhitebalValueRed',Result) then Result:=0;
end;

procedure TPvCamera.SetWhiteBalanceRed(Value:DWord);
begin
  WhiteBalance.Red:=Value;
  AbleToSetDWordParameter('WhitebalValueRed',Value);
end;

function TPvCamera.GetWhiteBalanceBlue:DWord;
begin
  if not AbleToGetDWordParameter('WhitebalValueBlue',Result) then Result:=0;
end;

procedure TPvCamera.SetWhiteBalanceBlue(Value:DWord);
begin
  WhiteBalance.Blue:=Value;
  AbleToSetDWordParameter('WhitebalValueBlue',Value);
end;

function TPvCamera.ModeToString(Mode:Integer):String;
begin
  Case Mode of
    ManualMode   : Result:='Manual';
    AutoMode     : Result:='Auto';
    AutoOnceMode : Result:='AutoOnce';
    else Result:='External';
  end;
end;

function TPvCamera.GetWhiteBalanceRate:DWord;
begin
  AbleToGetDWordParameter('WhitebalAutoRate',Result);
end;

procedure TPvCamera.SetWhiteBalanceRate(Rate:DWord);
begin
  WhiteBalance.Rate:=Rate;
  AbleToSetDWordParameter('WhitebalAutoRate',Rate);
end;

function TPvCamera.GetMultiCast : Boolean;
var
  Setting : String;
begin
  if AbleToGetEnumParameter('MulticastEnable',Setting) then begin
    Result:=(Setting='On');
  end
  else Result:=False;
end;

procedure TPvCamera.SetMultiCast(Value:Boolean);
var
  Setting : String;
begin
  if Value then Setting:='On'
  else Setting:='Off';
  AbleToSetEnumParameter('MulticastEnable',Setting);
end;

function TPvCamera.GetStreamBytesPerSecond:DWord;
begin
  if not AbleToGetDWordParameter('StreamBytesPerSecond',Result) then Result:=0;
end;

procedure TPvCamera.SetStreamBytesPerSecond(Value:DWord);
begin
  AbleToSetDWordParameter('StreamBytesPerSecond',Value);
end;

function TPvCamera.GetPacketSize:DWord;
begin
  if not AbleToGetDWordParameter('PacketSize',Result) then Result:=0;
end;

procedure TPvCamera.SetPacketSize(Size:DWord);
begin
  AbleToSetDWordParameter('PacketSize',Size);
end;

procedure TPvCamera.PickBestPacketSize(Max:DWord);
begin
  if Assigned(HCamera) then begin
    PvCaptureAdjustPacketSize(HCamera,Max);
  end;
end;

procedure TPvCamera.SetPvBinning(V:DWord);
begin
  if not AbleToSetDWordParameter('BinningX',V) then begin
    ShowMessage('Error setting X binning');
  end
  else if not AbleToSetDWordParameter('BinningY',V) then begin
    ShowMessage('Error setting Y binning');
  end;
  SizeBmpAndFrames;
end;

procedure TPvCamera.SetWindow(NewWindow:TCameraWindow);
begin
  Window:=NewWindow;
  if not AbleToSetDWordParameter('RegionX',Window.X) then begin
    ShowMessage('Error setting ROI X');
  end
  else if not AbleToSetDWordParameter('RegionY',Window.Y) then begin
    ShowMessage('Error setting ROI Y');
  end
  else if not AbleToSetDWordParameter('Width',Window.W) then begin
    ShowMessage('Error setting ROI width');
  end
  else if not AbleToSetDWordParameter('Height',Window.H) then begin
    ShowMessage('Error setting ROI height');
  end;
  SizeBmpAndFrames;
end;


end.
