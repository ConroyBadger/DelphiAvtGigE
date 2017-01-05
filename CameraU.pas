unit CameraU;

interface

uses
  DirectShow9, ActiveX, Classes, Windows, Graphics, Messages, Forms, Jpeg,
  Global, DShowUtils, FreeIm
  age, FreeImageUtils, MatrixU, ImageU, Ipl, PvAPI,
  OpenGL1x, OpenGLTokens;

const
  FrameRateAverages  = 10;
  MaxKImages         = 10;
  MaxRecordFrames    = 100;

  FrameSize = MaxImageW*MaxImageH;
  MaxFrames = 4;//16;

  ManualMode   = 0;
  AutoMode     = 1;
  AutoOnceMode = 2;
  ExternalMode = 3;

  MinGain = 0;
  MaxGain = 22;
  FrameRate = 15;

  MinTableX = -MaxImageW;
  MaxTableX = MaxImageW*2;
  MinTableY = -MaxImageH;
  MaxTableY = MaxImageH*2;

  NewFrameMsg = WM_USER+1;

type
  TCameraWindow = record
    X,Y,W,H : DWord;
  end;

  TProjectorTableEntry = record
    X,Y : Word;
  end;
  TProjectorTable =
    array[0..MaxImageW-1,0..MaxImageH-1] of TProjectorTableEntry;
  TProjectorTableFile = File of TProjectorTable;

  TGridTableEntry = record
    X,Y : Word;
  end;
  TGridTable =
    array[0..MaxImageW-1,0..MaxImageH-1] of TGridTableEntry;
  TGridTableFile = File of TGridTable;

  TUndistortTableEntry = record
    X,Y     : Integer;
    Valid   : Boolean;
    InImage : Boolean;
  end;
  TUndistortTable = array[MinTableX..MaxTableX,MinTableY..MaxTableY] of TUndistortTableEntry;

  TUndistortData = array[1..MaxImageW*MaxImageH] of Integer;

  TOnRecordUpdate = procedure(Sender:TObject;Percent:Integer) of Object;

  TCameraName = AnsiString;

  TWhiteBalance = record
    Mode : Integer;
    Red  : DWord;
    Blue : DWord;
    Rate : DWord;
  end;

type
  TExposure = record
    Mode                : String[255];
    Value               : DWord;  // microseconds
    AutoAdjustDelay     : DWord; // delay before making any adjustments
    AutoAdjustTolerance : DWord;
    AutoAlgorithm       : Integer; // 0=mean, 1=FitRange
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

  TJpgPath = String[50];

  TCameraInfo = packed record
    Gain         : TGain;
    Exposure     : TExposure;
    Pose         : TPose;
    KInfo        : TKInfo;
    JpgPath      : TJpgPath;
    FlipImage    : Boolean;
    MirrorImage  : Boolean;
    Debayer      : Boolean;
    Window       : TCameraWindow;
    WhiteBalance : TWhiteBalance;
    Reserved     : array[1..256] of Byte;
  end;

  TCamera = class(TObject)
  private
// private vars
    Frame       : TPvFrameArray;
    FrameData   : TFrameDataArray;
    FrameI      : Integer;
    PvStatus    : Integer;

    FOnNewFrame      : TNotifyEvent;
    FOnRecordUpdate  : TOnRecordUpdate;
    FOnSaveJpgUpdate : TOnRecordUpdate;
    JpgsCreated      : Boolean;

    FHandle         : THandle;
    LastSampleTime  : DWord;
    FrameRateFrame  : Integer;
    OwnerHandle     : THandle;
    CamIndex        : Integer;
    UndistortTable  : TUndistortTable;
    DistortTable    : TUndistortTable;
//    UndistMap       : PIplImage;}

    LastFPSTime : DWord;
    TextureName : DWord;

    ImageData : array[0..MaxImageW*MaxImageH-1] of Byte;

    function  GetInfo:TCameraInfo;
    procedure SetInfo(NewInfo:TCameraInfo);

    procedure CallBack(iFrame:PPvFrame); stdcall;
    procedure AddEnumsToStrings(Param:AnsiString;Strings:TStrings);
    procedure MeasureFPS(iFrame:PPvFrame);
    procedure WndProc(var Msg:TMessage);

    procedure UpdateRecording;
    procedure CreateJpgs;
    procedure FreeJpgs;
    procedure ApplyImageDataAsTexture;
    procedure CreateAndStoreTexture;
    procedure FreeTexture;

    function  GetMultiCast : Boolean;
    procedure SetMultiCast(Value:Boolean);

    function  GetStreamBytesPerSecond:DWord;
    procedure SetStreamBytesPerSecond(Value:DWord);

    function  GetPacketSize:DWord;
    procedure SetPacketSize(Size:DWord);
    procedure SetWindow(NewWindow:TCameraWindow);
    procedure SizeBmpAndFrames;
    function  LinePaddingForXSize(Size: Integer): Integer;

    function GridTableFileName: String;
    function ProjectorTableFileName: String;

  public
    HCamera    : Pointer;
    Running    : Boolean;
    ImageW     : Integer;
    ImageH     : Integer;
    Gain       : TGain;
    Exposure   : TExposure;
    Bmp        : TBitmap;

    Pose       : TPose;
    FrameCount : Integer;
    CameraName : AnsiString;
    KInfo      : TKInfo;
    DeBayer    : Boolean;
    MouseX     : Integer;
    MouseY     : Integer;

    Recording : Boolean;
    Jpg       : array[1..MaxRecordFrames] of TJpegImage;
    JpgPath   : TJpgPath;

    RawImage   : TImageIpl;
    FixedImage : TImageIpl;

    ProjTable : TProjectorTable;
    GridTable : TGridTable;

    MeasuredFPS : Single;

    FlipImage   : Boolean;
    MirrorImage : Boolean;
    RotateImage : Boolean;

    CS : TRTLCriticalSection;

    Window : TCameraWindow;
    WhiteBalance : TWhiteBalance;

    property OnNewFrame : TNotifyEvent read FOnNewFrame write FOnNewFrame;
    property OnRecordUpdate : TOnRecordUpdate read FOnRecordUpdate
                              write FOnRecordUpdate;
    property OnSaveJpgUpdate : TOnRecordUpdate read FOnSaveJpgUpdate
                              write FOnSaveJpgUpdate;

    property Info : TCameraInfo read GetInfo write SetInfo;

    property MultiCast : Boolean read GetMultiCast write SetMultiCast;

    property StreamBytesPerSecond : DWord read GetStreamBytesPerSecond
                                    write SetStreamBytesPerSecond;

    property PacketSize : DWord read GetPacketSize write SetPacketSize;

    constructor Create(iOwnerHandle:THandle);
    destructor Destroy; override;

    procedure UpdateWithJpg(Jpg:TJpegImage);
    function  Position:TPoint3D;
    procedure InitKMatrix(K:TMatrix);

    procedure ClipXPixel(var X:Integer);
    procedure ClipYPixel(var Y:Integer);
    procedure InitFromCalFile(FileName:String);

    procedure ShowCameraSettingsFrm(ShowVideo:Boolean);

    function  AbleToDistortPixel(FixedX,FixedY:Single;var RawX,RawY:Single):Boolean;
    function  AbleToUndistortPixel(RawX,RawY:Single;var FixedX,FixedY:Single):Boolean;

    procedure DrawUndistortedBmp(SrcBmp,DestBmp:TBitmap);
    procedure LoadDistortionTables;

    procedure MakeUndistortTable;
    procedure MakeDistortTable;
    procedure FillDistortTableGap(X,Y:Integer);
    function  ApiVersionString:String;
    function  CameraCount:Integer;
    procedure ShowDevicesInLines(Lines:TStrings);
    procedure UseFirstDevice;
    procedure Start;
    procedure Stop;

    function  AbleToGetDWordParameter(Param:AnsiString;var V:DWord):Boolean;
    function  AbleToSetDWordParameter(Param:AnsiString;var V:DWord):Boolean;

    procedure ShowInfoInLines(Lines:TStrings);
    function  ApiStatusString:String;

    procedure ReadGain;
    procedure ReadExposure;

    procedure FillExposureModeStrings(Strings:TStrings);
    procedure ShowSettingsFrm;
    procedure SetExposureMode(Mode:AnsiString);
    procedure SetExposure(V:DWord);
    procedure SetGain(V:DWord);

    function  AbleToGetEnumParameter(Param,Value:AnsiString):Boolean;
    function  AbleToSetEnumParameter(Param,Value:AnsiString):Boolean;
    procedure StartRecording;
    procedure SaveJpgs;
    procedure GetFrame;
    procedure DeBayerFrame(var iFrame:TPvFrame);
    procedure AssertSettings;
    function  Found:Boolean;
    procedure ShutDown;
    procedure BuildProjectorTable;
    procedure BuildGridTable;
    procedure Render(W,H:Integer);
    procedure PickBestPacketSize(Max:DWord);

    procedure SetPvBinning(V: DWord);
    procedure FakeBmp;

    function  GetWhiteBalanceMode: Integer;
    procedure SetWhiteBalanceMode(Mode: Integer);

    function  GetWhiteBalanceRed:DWord;
    procedure SetWhiteBalanceRed(Value:DWord);

    function  GetWhiteBalanceBlue:DWord;
    procedure SetWhiteBalanceBlue(Value:DWord);

    function  GetWhiteBalanceRate:DWord;
    procedure SetWhiteBalanceRate(Rate:DWord);
    function  ModeToString(Mode:Integer): String;
    procedure DrawWindow(Bmp: TBitmap);
    procedure ShowFullView;

    procedure SaveGridTable;
    procedure SaveProjectorTable;
    procedure LoadTables;
  end;

var
  Camera : TCamera;

function DefaultCameraInfo:TCameraInfo;

implementation

uses
  Dialogs, SysUtils, BmpUtils, Math, Controls, FileCtrl, CloudU,
  Routines, MathUnit, Math3D, {OpenCV,} Main, Normal, CalFile, FileU, CfgFile,
  CamSettingsFrmU, ProjectorU, GLDraw;

function DefaultCameraInfo:TCameraInfo;
begin
  with Result do begin
    Exposure.Mode:='Manual';
    Exposure.Value:=20000;
    Exposure.AutoAdjustDelay:=1000;
    Exposure.AutoAdjustTolerance:=10;
    Exposure.AutoAlgorithm:=0;
    Exposure.Min:=10000;
    Exposure.Max:=100000;

    Gain.Min:=0;
    Gain.Max:=22;
    Gain.Value:=8;

    FillChar(Pose,SizeOf(Pose),0);
    FillChar(KInfo,SizeOf(KInfo),0);
    JpgPath:='';

    FlipImage:=False;
    MirrorImage:=False;

    Debayer:=True;

    Window.X:=0;
    Window.Y:=0;
    Window.W:=MaxImageW;
    Window.H:=MaxImageH;

    Result.WhiteBalance.Mode:=AutoMode;
    Result.WhiteBalance.Red:=100;
    Result.WhiteBalance.Blue:=100;
    Result.WhiteBalance.Rate:=50;

    FillChar(Reserved,SizeOf(Reserved),0);
  end;
end;

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
  PostMessage(Camera.FHandle,NewFrameMsg,DWord(iFrame),0);
end;

procedure TCamera.MeasureFPS(iFrame:PPvFrame);
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

procedure TCamera.CallBack(iFrame:PPvFrame); stdcall;
begin
  if Assigned(iFrame) then begin
    ImageW:=iFrame.Width;
    ImageH:=iFrame.Height;

    if DeBayer then DeBayerFrame(iFrame^)
    else DrawFrameOnBmp(iFrame^,Bmp);

    MeasureFPS(iFrame);
    if Assigned(FOnNewFrame) then FOnNewFrame(Self);
    if Recording then UpdateRecording;
  end;
  if FrameI<MaxFrames then Inc(FrameI)
  else FrameI:=1;
  PvCaptureQueueFrame(HCamera,Frame[FrameI],@FrameCallBack);
end;

procedure TCamera.WndProc(var Msg:TMessage);
var
  FramePtr : PPvFrame;
begin
  if Msg.Msg=NewFrameMsg then begin
    FramePtr:=PPvFrame(Msg.wParam);
    CallBack(FramePtr);
    Msg.Result:=0;
  end
  else with Msg do begin
    Result:=DefWindowProc(FHandle,Msg,wParam,lParam);
  end;
end;

constructor TCamera.Create(iOwnerHandle:THandle);
var
  F : Integer;
begin
  inherited Create;
  OwnerHandle:=iOwnerHandle;

// init vars
  HCamera:=nil;
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
  DeBayer:=True;

// init the api
  PvStatus:=PvInitialize;

// init vars
  ImageW:=MaxImageW;
  ImageH:=MaxImageH;
  TextureName:=0;

  FOnNewFrame:=nil;
  FOnRecordUpdate:=nil;
  FOnSaveJpgUpdate:=nil;
  JpgsCreated:=False;

  FillChar(ImageData,SizeOf(ImageData),255);

  {RawImage:=TImageIpl.Create;
  RawImage.IplImage:=RawImage.CreateIplImageFromDefaultHeader(ImageW,ImageH);
  FixedImage:=TImageIpl.Create;
  FixedImage.IplImage:=FixedImage.CreateIplImageFromDefaultHeader(ImageW,ImageH);
  UndistMap:=nil;}

  Bmp:=CreateImageBmp;

  LastSampleTime:=0;
  FrameRateFrame:=0;
  FrameCount:=0;
  MeasuredFPS:=0;

  InitializeCriticalSection(CS);

  FHandle:=AllocateHWnd(WndProc);
end;

procedure TCamera.ShutDown;
begin
  DeAllocateHWnd(FHandle);

// close the camera
  if Assigned(HCamera) then begin
    if Running then Stop;
    PvCameraClose(HCamera);
  end;

// shut down the API
  if PvStatus=ePvErrSuccess then PvUnInitialize;
end;

destructor TCamera.Destroy;
begin
  ShutDown;

  DeleteCriticalSection(CS);

  FreeTexture;
  
// images
  if Assigned(Bmp) then Bmp.Free;

  if Assigned(RawImage) then RawImage.Free;
  if Assigned(FixedImage) then FixedImage.Free;

  DeAllocateHWnd(FHandle);

  inherited;
end;

function TCamera.GetInfo:TCameraInfo;
begin
  Result.Gain:=Gain;
  Result.Exposure:=Exposure;
  Result.Pose:=Pose;
  Result.KInfo:=KInfo;
  Result.JpgPath:=JpgPath;
  Result.FlipImage:=FlipImage;
  Result.MirrorImage:=MirrorImage;
  Result.Debayer:=Debayer;
  Result.Window:=Window;
  Result.WhiteBalance:=WhiteBalance;

  FillChar(Result.Reserved,SizeOf(Result.Reserved),0);
end;

procedure TCamera.SetInfo(NewInfo:TCameraInfo);
begin
  Gain:=NewInfo.Gain;
  Exposure:=NewInfo.Exposure;
  Pose:=NewInfo.Pose;
  KInfo:=NewInfo.KInfo;

//  KInfo.Px:=KInfo.Px/2;
//  KInfo.Py:=KInfo.Py/2;

  JpgPath:=NewInfo.JpgPath;
  FlipImage:=NewInfo.FlipImage;
  MirrorImage:=NewInfo.MirrorImage;
  Debayer:=NewInfo.Debayer;

  Window:=NewInfo.Window;
  if Window.W=0 then begin
    Window.X:=0;
    Window.Y:=0;
    Window.W:=MaxImageW;
    Window.H:=MaxImageH;
  end;
  WhiteBalance:=NewInfo.WhiteBalance;
end;

function TCamera.Found:Boolean;
begin
  Result:=Assigned(HCamera);
end;

procedure TCamera.UpdateWithJpg(Jpg:TJpegImage);
begin
  Inc(FrameCount);
  Bmp.Canvas.Draw(0,0,Jpg);
  if Assigned(FOnNewFrame) then FOnNewFrame(Self);
end;

function TCamera.Position:TPoint3D;
begin
  with Pose do begin
    Result.X:=X;
    Result.Y:=Y;
    Result.Z:=Z;
  end;
end;

procedure TCamera.InitKMatrix(K:TMatrix);
begin
  K.RowCount:=3; K.ColCount:=3;
  with KInfo do begin
    K.Cell[1,1]:=K1; K.Cell[1,2]:=Skew; K.Cell[1,3]:=Px;
    K.Cell[2,1]:=0;  K.Cell[2,2]:=K1;   K.Cell[2,3]:=Py;
    K.Cell[3,1]:=0;  K.Cell[3,2]:=0;    K.Cell[3,3]:=1;
  end;
end;

procedure TCamera.ClipXPixel(var X:Integer);
begin
  if X<0 then X:=0
  else if X>=ImageW then X:=ImageW-1;
end;

procedure TCamera.ClipYPixel(var Y:Integer);
begin
  if Y<0 then Y:=0
  else if Y>=ImageH then Y:=ImageH-1;
end;

procedure TCamera.InitFromCalFile(FileName:String);
var
  CalRecord : TCalFileRecord;
begin
  if AbleToLoadCalFile(FileName,CalRecord) then begin
    KInfo:=CalRecord.KInfo;
    MakeUndistortTable;
    SaveUndistortTable(UndistortTable,Path+'Undistort.dat');
    MakeDistortTable;
    SaveUndistortTable(DistortTable,Path+'Distort.dat');
  end
  else ShowMessage('Error loading calibration file "'+FileName+'"');
end;

procedure TCamera.ShowCameraSettingsFrm;
begin
  CamSettingsFrm:=TCamSettingsFrm.Create(Application);
  try
    CamSettingsFrm.Initialize;
    CamSettingsFrm.ShowModal;
  finally
    CamSettingsFrm.Free;
  end;
end;

procedure TCamera.FillDistortTableGap(X,Y:Integer);
const
  MaxR = 10;
var
  Xt,Yt       : Integer;
  Found       : Boolean;
  MinX,MaxX   : Integer;
  MinY,MaxY   : Integer;
  D,BestD     : Single;
  BestX,BestY : Integer;
begin
  MinX:=X-MaxR;
  if MinX<MinTableX then MinX:=MinTableX;
  MaxX:=X+MaxR;
  if MaxX>MaxTableX then MaxX:=MaxTableX;

  MinY:=Y-MaxR;
  if MinY<MinTableY then MinY:=MinTableY;
  MaxY:=Y+MaxR;
  if MaxY>MaxTableY then MaxY:=MaxTableY;

  Found:=False;
  for Yt:=MinY to MaxY do for Xt:=MinX to MaxX do begin
    if DistortTable[Xt,Yt].Valid then begin
      D:=Sqrt(Sqr(X-Xt)+Sqr(Y-Yt));
      if (not Found) or (D<BestD) then begin
        Found:=True;
        BestD:=D;
        BestX:=Xt;
        BestY:=Yt;
      end;
    end;
  end;
  if Found then DistortTable[X,Y]:=DistortTable[BestX,BestY];
end;

//******************************************************************************
// Creates a lookup table for finding the corresponding pixel in the fixed image
// for a given real camera image.
//******************************************************************************
procedure TCamera.MakeDistortTable;
var
  Xi,Yi     : Integer;
  Found     : Boolean;
  MinX,MaxX : Integer;
  MinY,MaxY : Integer;
begin
// clear the table
  for Yi:=MinTableY to MaxTableY do for Xi:=MinTableX to MaxTableX do begin
    DistortTable[Xi,Yi].Valid:=False;
    DistortTable[Xi,Yi].InImage:=False;
  end;
  if (KInfo.K1=400) or (KInfo.K1=0) then Exit;

// loop through the undistort table and steal the matches
  Found:=False;
  for Yi:=MinTableY to MaxTableY do for Xi:=MinTableX to MaxTableX do begin
    with UndistortTable[Xi,Yi] do if Valid then begin
      DistortTable[X,Y].X:=Xi;
      DistortTable[X,Y].Y:=Yi;
      DistortTable[X,Y].Valid:=True;
      DistortTable[X,Y].InImage:=(Xi>=0) and (Xi<MaxImageW) and
                                 (Yi>=0) and (Yi<MaxImageH);
      if not Found then begin
        Found:=True;
        MinX:=Xi;
        MaxX:=Xi;
        MinY:=Yi;
        MaxY:=Yi;
      end
      else begin
        if Xi<MinX then MinX:=Xi;
        if Xi>MaxX then MaxX:=Xi;
        if Yi<MinY then MinY:=Yi;
        if Yi>MaxY then MaxY:=Yi;
      end;
    end;
  end;

// fill in the gaps with the closest neighbour
  for Yi:=MinY to MaxY do for Xi:=MinX to MaxX do begin
    if not DistortTable[Xi,Yi].Valid then FillDistortTableGap(Xi,Yi);
  end;
end;

procedure TCamera.MakeUndistortTable;
var
  X,X1,X2,X3,Du : Single;
  Y,Y1,Y2,Y3,Dv : Single;
  A1,B1,R2,Dist : Single;
  Bx,By         : Single;
  U,V,Us,Vs     : Integer;
begin
  if (KInfo.K1=400) or (KInfo.K1=0) then begin
    for V:=MinTableY to MaxTableY do for U:=MinTableX to MaxTableX do begin
      UnDistortTable[U,V].Valid:=False;
    end;
    Exit;
  end;
  A1:=1/KInfo.K1;
  B1:=1/KInfo.K2;
  for V:=MinTableY to MaxTableY do begin
    Dv:=V-KInfo.Py;      //  float dv = v - v0;
    Y:=B1*Dv;            //  float y = b1 * (v - v0);
    if Y<>0 then Y1:=KInfo.D[3]/Y;
    Y2:=Y*Y;             //  float y2 = y * y;
    Y3:=2*KInfo.D[3]*Y;

// fill the table with the closest pixel x,y in the raw image
// some pixels may be mapped more than once
    for U:=MinTableX to MaxTableX do begin
      Du:=U-KInfo.Px;
      X:=A1*Du;
      if X<>0 then X1:=KInfo.D[4]/X;
      X2:=X*X;
      X3:=2*KInfo.D[4]*X;
      R2:=X2+Y2;
      Dist:=R2*(KInfo.D[1]+R2*KInfo.D[2])+X3+Y3;
      if (X=0) or (Y=0) then begin
        Bx:=Dist-X3-Y3;
        By:=Bx;
      end
      else begin
        Bx:=Dist+R2*X1;
        By:=Dist+R2*Y1;
      end;
      Us:=U+Round(Du*Bx);
      Vs:=V+Round(Dv*By);
      if (Us>=MinTableX) and (Us<=MaxTableX) and (Vs>=MinTableY) and (Vs<=MaxTableY) then begin
        UndistortTable[U,V].X:=Us;
        UndistortTable[U,V].Y:=Vs;
        UndistortTable[U,V].Valid:=True;
        UndistortTable[U,V].InImage:=(Us>=0) and (Us<ImageW) and (Vs>=0) and (Vs<ImageH);
      end
      else UnDistortTable[U,V].Valid:=False;
    end;
  end;
end;

function TCamera.AbleToDistortPixel(FixedX,FixedY:Single;var RawX,RawY:Single):Boolean;
var
  Xi,Yi : Integer;
begin
  Xi:=Round(FixedX);
  Yi:=Round(FixedY);
  if (Xi>=MinTableX) and (Xi<=MaxTableX) and
     (Yi>=MinTableY) and (Yi<=MaxTableY) and
      UndistortTable[Xi,Yi].Valid then
  begin
    RawX:=UndistortTable[Xi,Yi].X;
    RawY:=UndistortTable[Xi,Yi].Y;

    if RawX<0 then RawX:=0
    else if RawX>=ImageW then RawX:=ImageW-1;
    if RawY<0 then RawY:=0
    else if RawY>=ImageH then RawY:=ImageH-1;

    Result:=True;
  end
  else Result:=False;
end;

function TCamera.AbleToUndistortPixel(RawX,RawY:Single;var FixedX,FixedY:Single):Boolean;
var
  Xi,Yi : Integer;
begin
  Xi:=Round(RawX); Yi:=Round(RawY);
  if (Xi>=MinTableX) and (Xi<=MaxTableX) and
     (Yi>=MinTableY) and (Yi<=MaxTableY) and
      DistortTable[Xi,Yi].Valid then
  begin
    FixedX:=DistortTable[Xi,Yi].X;
    FixedY:=DistortTable[Xi,Yi].Y;
    Result:=True;
  end
  else Result:=False;
end;

procedure TCamera.DrawUndistortedBmp(SrcBmp,DestBmp:TBitmap);
var
  SrcLines : array[0..MaxImageH-1] of PByteArray;
  SrcLine  : PByteArray;
  DestLine : PByteArray;
  X,Y,SrcI : Integer;
  DestI    : Integer;
begin
  for Y:=0 to ImageH-1 do SrcLines[Y]:=SrcBmp.ScanLine[Y];
  for Y:=0 to ImageH-1 do begin
    DestLine:=DestBmp.ScanLine[Y];
    DestI:=0;
    for X:=0 to ImageW-1 do begin
      if UnDistortTable[X,Y].Valid then begin
        SrcI:=UnDistortTable[X,Y].X*3;
        SrcLine:=SrcLines[UnDistortTable[X,Y].Y];
        DestLine^[DestI+0]:=SrcLine^[SrcI+0];
        DestLine^[DestI+1]:=SrcLine^[SrcI+1];
        DestLine^[DestI+2]:=SrcLine^[SrcI+2];
      end;
      DestI:=DestI+3;
    end;
  end;
end;

procedure TCamera.LoadDistortionTables;
begin
  if not AbleToLoadUndistortTable(UndistortTable,Path+'Undistort.dat') then
  begin
    MakeUndistortTable;
    SaveUndistortTable(UndistortTable,Path+'Undistort.dat');
  end;
  if not AbleToLoadUndistortTable(DistortTable,Path+'Distort.dat') then begin
    MakeDistortTable;
    SaveUndistortTable(DistortTable,Path+'Distort.dat');
  end;
end;

function TCamera.ApiVersionString:String;
var
  Major,Minor : DWord;
begin
  PvVersion(Major,Minor);
  Result:='API version '+IntToStr(Major)+'.'+IntToStr(Minor);
end;

function TCamera.CameraCount:Integer;
begin
  Result:=PvCameraCount;
end;

procedure TCamera.ShowDevicesInLines(Lines:TStrings);
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

procedure TCamera.UseFirstDevice;
var
  CameraInfo : TPvCameraInfoArray;
  Count      : DWord;
  Found      : DWord;
  RC,I       : Integer;
begin
  CameraName:='No camera';

// count the cameras
  Count:=PvCameraList(@CameraInfo[1],1,Found);

// open the first one if we found any
  if (Count>0) and (Found>0) then begin
    RC:=PvCameraOpen(CameraInfo[1].UniqueID,ePvAccessMaster,HCamera);
    if RC=ePvErrSuccess then begin

// get the name - look for the null
      I:=0;
      repeat
        Inc(I);
      until (I=SizeOf(CameraInfo[1].DisplayName)) or (CameraInfo[1].DisplayName[I]=#0);

// copy it up to just before the null
      SetLength(CameraName,I-1);
      Move(CameraInfo[1].DisplayName[1],CameraName[1],I-1);
    end
    else if Assigned(HCamera) then begin
      PvCameraClose(HCamera);
      HCamera:=nil;
    end;
  end
end;

procedure TCamera.ShowInfoInLines(Lines:TStrings);
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

  if AbleToGetDWordParameter('Width',V) then begin
    Lines.Add('Width: '+IntToStr(V));
  end
  else Lines.Add('Error getting width');

  if AbleToGetDWordParameter('Height',V) then begin
    Lines.Add('Height: '+IntToStr(V));
  end
  else Lines.Add('Error getting sensor height');

end;

function TCamera.AbleToGetDWordParameter(Param:AnsiString;var V:DWord):Boolean;
begin
  Result:=Assigned(HCamera) and
         (PvAttrUint32Get(HCamera,PAnsiChar(Param),V)=ePvErrSuccess);
end;

function TCamera.AbleToSetDWordParameter(Param:AnsiString;var V:DWord):Boolean;
begin
  Result:=Assigned(HCamera) and
         (PvAttrUint32Set(HCamera,PAnsiChar(Param),V)=ePvErrSuccess);
end;

function TCamera.AbleToGetEnumParameter(Param,Value:AnsiString):Boolean;
const
  MaxSize = 255;
var
  Size : DWord;
begin
  Result:=False;
  if Assigned(HCamera) then begin
    SetLength(Value,MaxSize);
    if PvAttrEnumGet(HCamera,PAnsiChar(Param),@Value[1],MaxSize,Size)=ePvErrSuccess
    then begin
      SetLength(Value,Size);
    end;
  end;
end;

function TCamera.AbleToSetEnumParameter(Param,Value:AnsiString):Boolean;
begin
  Result:=False;
  if Assigned(HCamera) then begin
    Result:=PvAttrEnumSet(HCamera,PAnsiChar(Param),PAnsiChar(Value))=ePvErrSuccess;
  end;
end;

procedure TCamera.Start;
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

procedure TCamera.Stop;
begin
  if Assigned(HCamera) then begin
    PvCaptureEnd(HCamera);
    Running:=False;
  end;
end;

function TCamera.ApiStatusString:String;
begin
  Case PvStatus of
    ePvErrSuccess       : Result:='Pv DLL version '+ApiVersionString+' initialized';
    ePvErrResources     : Result:='Out of resources';
    ePvErrInternalFault : Result:='Driver error';
    else Result:='???';
  end;
end;

procedure TCamera.ReadGain;
begin
  Gain.Min:=MinGain;
  Gain.Max:=MaxGain;
  AbleToGetDWordParameter('GainValue',Gain.Value);
end;

procedure TCamera.ReadExposure;
begin
  AbleToGetEnumParameter('ExposureMode',Exposure.Mode);
  Exposure.Min:=0;
  if FrameRate<1 then Exposure.Max:=1000000
  else Exposure.Max:=500000;//Round(1000000/FrameRate);
  AbleToGetDWordParameter('ExposureValue',Exposure.Value);
end;

procedure TCamera.AddEnumsToStrings(Param:AnsiString;Strings:TStrings);
const
  MaxSize = 1024;
var
  RC,I,I1 : Integer;
  I2      : Integer;
  Buffer  : array[1..MaxSize] of AnsiChar;
  SubStr  : String;
  Size    : DWord;
begin
  Strings.Clear;
  if Assigned(HCamera) then begin
    RC:=pvAttrRangeEnum(HCamera,PAnsiChar(Param),@Buffer[1],MaxSize,Size);
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

procedure TCamera.FillExposureModeStrings(Strings:TStrings);
begin
  AddEnumsToStrings('ExposureMode',Strings);
end;

procedure TCamera.ShowSettingsFrm;
begin
  CamSettingsFrm:=TCamSettingsFrm.Create(Application);
  try
    CamSettingsFrm.Initialize;
    CamSettingsFrm.ShowModal;
  finally
    CamSettingsFrm.Free;
  end;
end;

procedure TCamera.SetExposureMode(Mode:AnsiString);
begin
  AbleToSetEnumParameter('ExposureMode',Mode);
end;

procedure TCamera.SetExposure(V:DWord);
begin
  AbleToSetDWordParameter('ExposureValue',V);
  Exposure.Value:=V;
end;

procedure TCamera.SetGain(V:DWord);
begin
  AbleToSetDWordParameter('GainValue',V);
  Gain.Value:=V;
end;

procedure TCamera.CreateJpgs;
var
  I : Integer;
begin
  Assert(not JpgsCreated,'');
  for I:=1 to MaxRecordFrames do begin
    Jpg[I]:=TJpegImage.Create;
    Jpg[I].CompressionQuality:=100;
  end;
  JpgsCreated:=True;
end;

procedure TCamera.FreeJpgs;
var
  I : Integer;
begin
  Assert(JpgsCreated,'');
  for I:=1 to MaxRecordFrames do Jpg[I].Free;
  JpgsCreated:=False;
end;

function FrameIndexToJpgFileName(I:Integer):String;
begin
  Result:=Path+ThreeDigitIntStr(I)+'.jpg';
end;

procedure TCamera.SaveJpgs;
var
  I        : Integer;
  FileName : String;
begin
  Assert(JpgsCreated,'');
  if not DirectoryExists(JpgPath) then CreateDir(JpgPath);
  for I:=1 to MaxRecordFrames do begin
    FrameCount:=I;
    FileName:=JpgPath+FrameIndexToJpgFileName(I);
    Jpg[I].SaveToFile(FileName);
    if Assigned(FOnSaveJpgUpdate) then begin
      FOnSaveJpgUpdate(Self,Round(100*I/MaxRecordFrames));
    end;
  end;
end;

procedure TCamera.StartRecording;
begin
  Recording:=True;
  if not JpgsCreated then CreateJpgs;
  FrameCount:=0;
end;

procedure TCamera.UpdateRecording;
begin
  if FrameCount<=MaxRecordFrames then begin
    Jpg[FrameCount].Assign(Bmp);
    if Assigned(FOnRecordUpdate) then begin
      FOnRecordUpdate(Self,Round(100*FrameCount/MaxRecordFrames));
    end;
  end
  else begin
    Recording:=False;
    FOnRecordUpdate(Self,100);
  end;
end;

procedure TCamera.GetFrame;
begin
  if FrameI<MaxFrames then Inc(FrameI)
  else FrameI:=1;
  PvCaptureQueueFrame(HCamera,Frame[FrameI],nil);
  ImageW:=Frame[FrameI].Width;
  ImageH:=Frame[FrameI].Height;
  DrawFrameOnBmp(Frame[FrameI],Bmp);
  MeasureFPS(@Frame[FrameI]);
  if Assigned(FOnNewFrame) then FOnNewFrame(Self);
end;

function TCamera.LinePaddingForXSize(Size:Integer):Integer;
begin
  Result:=((Size+3) and (not 3))-Size;
end;

procedure TCamera.DeBayerFrame(var iFrame:TPvFrame);
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

procedure TCamera.AssertSettings;
begin
 // SetWindow(Window);

  SetExposureMode('Manual');
  SetExposure(Exposure.Value);
  SetGain(Gain.Value);

  SetWhiteBalanceMode(WhiteBalance.Mode);
  SetWhiteBalanceRate(WhiteBalance.Rate);
  SetWhiteBalanceRed(WhiteBalance.Red);
  SetWhiteBalanceBlue(WhiteBalance.Blue);
end;

procedure TCamera.BuildProjectorTable;
var
  X,Y    : Integer;
  ProjPt : TPixel;
begin
  for X:=0 to ImageW-1 do for Y:=0 to ImageH-1 do begin
    ProjPt:=Projector.PixelFromCamXY(X,Y);
    ProjTable[X,Y].X:=ProjPt.X;
    ProjTable[X,Y].Y:=ProjPt.Y;
  end;
end;

procedure TCamera.BuildGridTable;
var
  X,Y   : Integer;
  Xp,Yp : Integer;
begin
  for X:=0 to ImageW-1 do for Y:=0 to ImageH-1 do begin

// convert from camera pixels to projector pixels
    Xp:=ProjTable[X,Y].X;
    Yp:=ProjTable[X,Y].Y;

// scale from projector pixels to grid pixels
    with Cloud do begin
      GridTable[X,Y].X:=ClipToMax(Xp*GridWidth/ViewPortWidth,GridWidth);
      GridTable[X,Y].Y:=ClipToMax(GridHeight-Yp*GridHeight/ViewPortHeight,GridHeight);
    end;
  end;
end;

procedure TCamera.Render(W,H:Integer);
var
  HW,HH : Single;
begin
  HW:=W/2; HH:=H/2;
  RotateImage:=False;
  FillChar(ImageData,SizeOf(ImageData),255);

  ApplyImageDataAsTexture;
  if RotateImage then begin
    if FlipImage then begin
      if MirrorImage then begin
        RenderTexturedRectangleRotatedMirroredAndFlipped(HW,HH,W,H,1);
      end
      else begin
        RenderTexturedRectangleRotatedAndFlipped(HW,HH,W,H,1);
      end;
    end
    else if MirrorImage then begin
      RenderTexturedRectangleRotatedAndMirrored(HW,HH,W,H,1);
    end
    else begin
      RenderTexturedRectangleRotated(HW,HH,W,H,1);
    end;
  end
  else begin
    RenderTexturedRectangle(0,0,W,H,1);

//    RenderTexturedRectangleMirroredAndFlipped(HW,HH,W,H,1);
  end;
end;

const
  TextureW = 640;
  TextureH = 480;

procedure TCamera.ApplyImageDataAsTexture;
var
  Data : PByte;
begin
  if TextureName=0 then CreateAndStoreTexture;

  EnterCriticalSection(CS);

  Data:=@ImageData[0];
  glBindTexture(GL_TEXTURE_2D,TextureName);
  glTexSubImage2D(GL_TEXTURE_2D,0,0,0,TextureW,TextureH,GL_BGR,GL_UNSIGNED_BYTE,Data);

  LeaveCriticalSection(CS);
end;

procedure TCamera.CreateAndStoreTexture;
var
  Data : PByte;
begin
  glGenTextures(1,@TextureName);
  glBindTexture(GL_TEXTURE_2D,TextureName);

// set it to repeat in S and T
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);

// set the filters
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);//GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);//GL_LINEAR);

  Data:=@ImageData[0];
  glTexImage2D(GL_TEXTURE_2D,0,3,TextureW,TextureH,0,GL_BGR,GL_UNSIGNED_BYTE,Data);
end;

procedure TCamera.FreeTexture;
begin
  if TextureName>0 then glDeleteTextures(1,@TextureName);
end;

function TCamera.GetMultiCast : Boolean;
var
  Setting : String;
begin
  if AbleToGetEnumParameter('MulticastEnable',Setting) then begin
    Result:=(Setting='On');
  end
  else Result:=False;
end;

procedure TCamera.SetMultiCast(Value:Boolean);
var
  Setting : String;
begin
  if Value then Setting:='On'
  else Setting:='Off';
  AbleToSetEnumParameter('MulticastEnable',Setting);
end;

function TCamera.GetStreamBytesPerSecond:DWord;
begin
  if not AbleToGetDWordParameter('StreamBytesPerSecond',Result) then Result:=0;
end;

procedure TCamera.SetStreamBytesPerSecond(Value:DWord);
begin
  AbleToSetDWordParameter('StreamBytesPerSecond',Value);
end;

function TCamera.GetPacketSize:DWord;
begin
  if not AbleToGetDWordParameter('PacketSize',Result) then Result:=0;
end;

procedure TCamera.SetPacketSize(Size:DWord);
begin
  AbleToSetDWordParameter('PacketSize',Size);
end;

procedure TCamera.PickBestPacketSize(Max:DWord);
begin
  if Assigned(HCamera) then begin
    PvCaptureAdjustPacketSize(HCamera,Max);
  end;
end;

procedure TCamera.FakeBmp;
const
  Size = 20;
var
  Shadow : TRect;
  X1,X2  : Integer;
  Y1,Y2  : Integer;
begin
  X1:=MouseX-Size;
  X2:=MouseX+Size;
  Y1:=Round(MaxImageH*0.75);
  Y2:=MaxImageH;

  Shadow:=Rect(X1,Y1,X2,Y2);

  Bmp.Canvas.Brush.Style:=bsSolid;
  ClearBmp(Bmp,clWhite);
  Bmp.Canvas.Brush.Color:=clBlack;
  Bmp.Canvas.FillRect(Shadow);
end;

procedure TCamera.SizeBmpAndFrames;
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

procedure TCamera.SetWindow(NewWindow:TCameraWindow);
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

procedure TCamera.SetPvBinning(V:DWord);
begin
  if not AbleToSetDWordParameter('BinningX',V) then begin
    ShowMessage('Error setting X binning');
  end
  else if not AbleToSetDWordParameter('BinningY',V) then begin
    ShowMessage('Error setting Y binning');
  end;
  SizeBmpAndFrames;
end;

procedure TCamera.ShowFullView;
begin
  if AbleToGetDWordParameter('SensorWidth',Window.W) and
     AbleToGetDWordParameter('SensorHeight',Window.H) then
  begin
    Window.X:=0;
    Window.Y:=0;
    SetWindow(Window);
  end;
end;

function TCamera.GetWhiteBalanceMode:Integer;
var
  ModeStr : String;
begin
  AbleToGetEnumParameter('WhitebalMode',ModeStr);
  if ModeStr='Auto' then Result:=AutoMode
  else Result:=ManualMode;
end;

procedure TCamera.SetWhiteBalanceMode(Mode:Integer);
var
  ModeStr : String;
begin
  WhiteBalance.Mode:=Mode;
  ModeStr:=ModeToString(Mode);
  AbleToSetEnumParameter('WhitebalMode',ModeStr);
end;

function TCamera.GetWhiteBalanceRed:DWord;
begin
  AbleToGetDWordParameter('WhitebalValueRed',Result);
end;

procedure TCamera.SetWhiteBalanceRed(Value:DWord);
begin
  WhiteBalance.Red:=Value;
  AbleToSetDWordParameter('WhitebalValueRed',Value);
end;

function TCamera.GetWhiteBalanceBlue:DWord;
begin
  AbleToGetDWordParameter('WhitebalValueBlue',Result);
end;

procedure TCamera.SetWhiteBalanceBlue(Value:DWord);
begin
  WhiteBalance.Blue:=Value;
  AbleToSetDWordParameter('WhitebalValueBlue',Value);
end;

function TCamera.ModeToString(Mode:Integer):String;
begin
  Case Mode of
    ManualMode   : Result:='Manual';
    AutoMode     : Result:='Auto';
    AutoOnceMode : Result:='AutoOnce';
    else Result:='External';
  end;
end;

function TCamera.GetWhiteBalanceRate:DWord;
begin
  AbleToGetDWordParameter('WhitebalAutoRate',Result);
end;

procedure TCamera.SetWhiteBalanceRate(Rate:DWord);
begin
  WhiteBalance.Rate:=Rate;
  AbleToSetDWordParameter('WhitebalAutoRate',Rate);
end;

procedure TCamera.DrawWindow(Bmp:TBitmap);
begin
  with Bmp.Canvas do begin
    Pen.Color:=clYellow;
    with Window do begin
      MoveTo(X,Y);
      LineTo(X+W,Y);
      LineTo(X+W,Y+H);
      LineTo(X,Y+H);
      LineTo(X,Y);
    end;
  end;
end;

function TCamera.ProjectorTableFileName:String;
begin
  Result:=Path+'Projector.dat';
end;

function TCamera.GridTableFileName:String;
begin
  Result:=Path+'Grid.dat';
end;

procedure TCamera.LoadTables;
var
  ProjectorFile : TProjectorTableFile;
  GridFile      : TGridTableFile;
  FileName      : String;
begin
// distortion
  LoadDistortionTables;

// projector
  FileName:=ProjectorTableFileName;
  if FileExists(FileName) and (SizeOfFile(FileName)=SizeOf(ProjTable)) then begin
    AssignFile(ProjectorFile,FileName);
    try
      Reset(ProjectorFile);
      Read(ProjectorFile,ProjTable);
    finally
      CloseFile(ProjectorFile);
    end;
  end
  else begin
    BuildProjectorTable;
    SaveProjectorTable;
  end;

// grid
  FileName:=GridTableFileName;
  if FileExists(FileName) and (SizeOfFile(FileName)=SizeOf(GridTable)) then begin
    AssignFile(GridFile,FileName);
    try
      Reset(GridFile);
      Read(GridFile,GridTable);
    finally
      CloseFile(GridFile);
    end;
  end
  else begin
    BuildGridTable;
    SaveGridTable;
  end;
end;

procedure TCamera.SaveProjectorTable;
var
  ProjectorFile : TProjectorTableFile;
  FileName      : String;
begin
// projector
  FileName:=ProjectorTableFileName;
  AssignFile(ProjectorFile,FileName);
  try
    Rewrite(ProjectorFile);
    Write(ProjectorFile,ProjTable);
  finally
    CloseFile(ProjectorFile);
  end;
end;

procedure TCamera.SaveGridTable;
var
  GridFile : TGridTableFile;
  FileName : String;
begin
// grid
  FileName:=GridTableFileName;
  AssignFile(GridFile,FileName);
  try
    Rewrite(GridFile);
    Write(GridFile,GridTable);
  finally
    CloseFile(GridFile);
  end;
end;

end.
