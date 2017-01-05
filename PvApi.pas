 unit PvApi;

interface

uses
  Windows;

const
  MaxCameras = 8;

  PvInfinite = $FFFFFFFF; // Never timeout

  ePvErrSuccess        = 0;  // No error
  ePvErrCameraFault    = 1;  // Unexpected camera fault
  ePvErrInternalFault  = 2;  // Unexpected fault in PvApi or driver
  ePvErrBadHandle      = 3;  // Camera handle is invalid
  ePvErrBadParameter   = 4;  // Bad parameter to API call
  ePvErrBadSequence    = 5;  // Sequence of API calls is incorrect
  ePvErrNotFound       = 6;  // Camera or attribute not found
  ePvErrAccessDenied   = 7;  // Camera cannot be opened in the specified mode
  ePvErrUnplugged      = 8;  // Camera was unplugged
  ePvErrInvalidSetup   = 9;  // Setup is invalid (an attribute is invalid)
  ePvErrResources      = 10; // System/network resources or memory not available
  ePvErrBandwidth      = 11; // 1394 bandwidth not available
  ePvErrQueueFull      = 12; // Too many frames on queue
  ePvErrBufferTooSmall = 13; // Frame buffer is too small
  ePvErrCancelled      = 14; // Frame cancelled by user
  ePvErrDataLost       = 15; // The data for the frame was lost
  ePvErrDataMissing    = 16; // Some data in the frame is missing
  ePvErrTimeout        = 17; // Timeout during wait
  ePvErrOutOfRange     = 18; // Attribute value is out of the expected range
  ePvErrWrongType      = 19; // Attribute is not this type (wrong access function)
  ePvErrForbidden      = 20; // Attribute write forbidden at this time
  ePvErrUnavailable    = 21; // Attribute is not available at this time
  ePvErrFirewall       = 22; // A firewall is blocking the traffic (Windows only)

// access flags
  ePvAccessMonitor     : Integer = 2; // Monitor access: no control, read & listen only
  ePvAccessMaster      : Integer = 4; // Master access: full control

// Camera interface type (i.e. firewire, ethernet):
  ePvInterfaceFirewire    : Integer = 1;
  ePvInterfaceEthernet    : Integer = 2;

// IP configuration mode for ethernet cameras.
  ePvIpConfigPersistent   : Integer = 1;            // Use persistent IP settings
  ePvIpConfigDhcp         : Integer = 2;            // Use DHCP, fallback to AutoIP
  ePvIpConfigAutoIp       : Integer = 4;            // Use AutoIP only

// Link (aka interface) event type
  ePvLinkAdd         : Integer = 1; // A camera was plugged in
  ePvLinkRemove      : Integer = 2; // A camera was unplugged
  _ePvLink_reserved1 : Integer = 3;

// Frame image format type
  ePvFmtMono8   : Integer = 0;  // Monochrome, 8 bits
  ePvFmtMono16  : Integer = 1;  // Monochrome, 16 bits, data is LSB aligned
  ePvFmtBayer8  : Integer = 2;  // Bayer-color, 8 bits
  ePvFmtBayer16 : Integer = 3;  // Bayer-color, 16 bits, data is LSB aligned
  ePvFmtRgb24   : Integer = 4;  // RGB, 8 bits x 3
  ePvFmtRgb48   : Integer = 5;  // RGB, 16 bits x 3, data is LSB aligned
  ePvFmtYuv411  : Integer = 6;  // YUV 411
  ePvFmtYuv422  : Integer = 7;  // YUV 422
  ePvFmtYuv444  : Integer = 8;  // YUV 444
  ePvFmtBgr24   : Integer = 9;  // BGR, 8 bits x 3
  ePvFmtRgba32  : Integer = 10; // RGBA, 8 bits x 4
  ePvFmtBgra32  : Integer = 11; // BGRA, 8 bits x 4

// Bayer pattern - Applicable when a Bayer-color camera is sending raw bayer data.
  ePvBayerRGGB : Integer = 0; // First line RGRG, second line GBGB...
  ePvBayerGBRG : Integer = 1; // First line GBGB, second line RGRG...
  ePvBayerGRBG : Integer = 2; // First line GRGR, second line BGBG...
  ePvBayerBGGR : Integer = 3; // First line BGBG, second line GRGR...

// Attribute data type supported
  ePvDatatypeUnknown  : Integer = 0;
  ePvDatatypeCommand  : Integer = 1;
  ePvDatatypeRaw      : Integer = 2;
  ePvDatatypeString   : Integer = 3;
  ePvDatatypeEnum     : Integer = 4;
  ePvDatatypeUint32   : Integer = 5;
  ePvDatatypeFloat32  : Integer = 6;

// Attribute flags type
  ePvFlagRead     : Integer = $01; // Read access is permitted
  ePvFlagWrite    : Integer = $02; // Write access is permitted
  ePvFlagVolatile : Integer = $04; // The camera may change the value any time
  ePvFlagConst    : Integer = $08; // Value is read only and never changes

type
  TPvErr            = Integer;
  TPvAccessFlags    = Integer;
  TPvInterface      = Integer;
  TPvIpConfig       = Integer;
  TPvLinkEvent      = Integer;
  TPvImageFormat    = Integer;
  TPvBayerPattern   = Integer;
  TPvDataType       = Integer;
  TPvAttributeFlags = Integer;

  TPvHandle = Pointer;

  TPvCameraInfo = record
    UniqueId        : DWord;                // Unique value for each camera
    SerialString    : array[1..32] of Char; // Camera's serial number
    PartNumber      : DWord;                // Camera part number
    PartVersion     : DWord;                // Camera part version
    PermittedAccess : DWord;                // A combination of tPvAccessFlags
    InterfaceId     : DWord;                // Unique value for each interface or bus
    InterfaceType   : Integer;
    DisplayName     : array[1..16] of Char; // People-friendly camera name
    _Reserved       : array[1..4] of DWord; // Always zero
  end;
  PPvCameraInfo = ^TPvCameraInfo;

  TPvCameraInfoArray = array[1..MaxCameras] of TPvCameraInfo;

// Structure used for PvCameraIpSettingsGet() and PvCameraIpSettingsChange().
  TPvIpSettings = record

// IP configuration mode: persistent, DHCP & AutoIp, or AutoIp only.
    ConfigMode : Integer;

// IP configuration mode supported by the camera
    ConfigModeSupport : DWord;

// Current IP configuration.  Ignored for PvCameraIpSettingsChange().  All
// values are in network byte order (i.e. big endian).
    CurrentIpAddress : DWord;
    CurrentIpSubnet  : DWord;
    CurrentIpGateway : DWord;

// Persistent IP configuration.  See "ConfigMode" to enable persistent IP
// settings.  All values are in network byte order.
    PersistentIpAddr    : DWord;
    PersistentIpSubnet  : DWord;
    PersistentIpGateway : DWord;
    _Reserved1          : array[1..8] of DWord;
  end;

// Link (aka interface) event Callback type
//
// Arguments:
//
//  [i] void* Context,          Context, as provided to PvLinkCallbackRegister
//  [i] tPvInterface Interface, Interface on which the event occurred
//  [i] tPvLinkEvent Event,     Event which occurred
//  [i] unsigned long UniqueId, Unique ID of the camera related to the event
//
  TPvLinkCallBack = procedure(Context:Pointer;IFace:TPvInterface;
                              Event:TPvLinkEvent;UniqueID:DWord);

// The frame structure passed to PvQueueFrame().
  TPvFrame = record
    ImageBuffer         : Pointer;
    ImageBufferSize     : DWord;     // Size of your image buffer in bytes
    AncillaryBuffer     : Pointer;   // Your buffer to capture associated header & trailer data for this image.
    AncillaryBufferSize : DWord; // Size of your ancillary buffer in bytes (can be 0 for no buffer).
    Context             : array[1..4] of Pointer;
    _Reserved1          : array[1..8] of DWord;
    Status         : TPvErr;
    ImageSize      : DWord;           // Image size, in bytes
    AncillarySize  : DWord;           // Ancillary data size, in bytes
    Width          : DWord;           // Image width
    Height         : DWord;           // Image height
    RegionX        : DWord;           // Start of readout region (left)
    RegionY        : DWord;           // Start of readout region (top)
    Format         : TPvImageFormat;  // Image format
    BitDepth       : DWord;           // Number of significant bits
    BayerPattern   : TPvBayerPattern; // Bayer pattern, if bayer format
    FrameCount     : DWord;           // Rolling frame counter
    TimeStampLo    : DWord;           // Time stamp, lower 32-bits
    TimestampHi    : DWord;           // Time stamp, upper 32-bits
    _Reserved2     : array[1..32] of DWord;
  end;
  PPvFrame = ^TPvFrame;

// Frame Callback type
// Arguments:
//  [i] tPvFrame* Frame, Frame completed
  TPvFrameCallBack = procedure(Frame:PPvFrame);
  PPvFrameCallBack = ^TPvFrameCallBack;

//----- Attributes ------------------------------------------------------------
  TPvInt32   = LongInt; // 32-bit integer
  TPvUInt32  = DWord;  // 32-bit unsigned integer
  TPvFloat32 = Single;

// List of attributes, used by PvAttrList.  This is an array of string
// pointers.  The array, and all the string pointers, are const.
  TPvAttrListPtr = Pointer; // typedef const char* const* tPvAttrListPtr;

// Attribute information type
  TPvAttributeInfo = record
    DataType  : TPvDataType;           // Data type
    Flags     : DWord;                 // Combination of tPvAttribute flags
    Category  : PChar;                 // Advanced: see documentation
    Impact    : PChar;                 // Advanced: see documentation
    _Reserved : array[1..4] of DWord;  // Always zero
  end;

//===== FUNCTION PROTOTYPES ===================================================
procedure PvVersion(var Major,Minor:DWord); stdcall;
function  PvInitialize:TPvErr; stdcall;
procedure PvUnInitialize; stdcall;

function  PvLinkCallbackRegister(CallBack:TPvLinkCallback;Event:TPvLinkEvent;
                                 Context:Pointer):TPvErr; stdcall;

function PvLinkCallbackUnRegister(CallBack:TPvLinkCallBack;
                                  Event:TPvLinkEvent):TPvErr; stdcall;

function PvCameraList(List:PPvCameraInfo;ListLength:DWord;
                      var ConnectedNum:DWord):DWord; stdcall;

function PvCameraCount:DWord; stdcall;
function PvCameraInfo(UniqueId:DWord;var Info:TPvCameraInfo):TPvErr; stdcall;

function PvCameraInfoByAddr(IpAddr:DWord;var Info:TPvCameraInfo;
                            var IpSettings:TPvIpSettings):TPvErr; stdcall;

function PvCameraListUnreachable(var List:TPvCameraInfo;ListLength:DWord;
                                 var ConnectedNum:DWord):DWord; stdcall;

function PvCameraOpen(UniqueId:DWord;AccessFlag:TPvAccessFlags;
                      var Camera:TPvHandle):TPvErr; stdcall;

function PvCameraOpenByAddr(IpAddr:DWord;AccessFlag:TPvAccessFlags;
                            var Camera:TPvHandle):TPvErr; stdcall;

function PvCameraClose(Camera:TPvHandle):TPvErr; stdcall;

function PvCameraIpSettingsGet(UniqueId:DWord;var Settings:TPvIpSettings):TPvErr; stdcall;

function PvCameraIpSettingsChange(UniqueId:DWord;const Settings:TPvIpSettings):TPvErr; stdcall;

function PvCaptureStart(Camera:TPvHandle):TPvErr; stdcall;
function PvCaptureEnd(Camera:TPvHandle):TPvErr; stdcall;

function PvCaptureQuery(Camera:TPvHandle;var IsStarted:DWord):TPvErr; stdcall;

function PvCaptureAdjustPacketSize(Camera:TPvHandle;
                                   MaximumPacketSize:DWord):TPvErr; stdcall;

function PvCaptureQueueFrame(Camera:TPvHandle;var Frame:TPvFrame;
                             CallBack:TPvFrameCallback):TPvErr; stdcall;

function PvCaptureQueueClear(Camera:TPvHandle):TPvErr; stdcall;

function PvCaptureWaitForFrameDone(Camera:TPvHandle;const Frame:TPvFrame;
                                   TimeOut:DWord):TPvErr; stdcall;

function PvAttrList(Camera:TPvHandle;var pListPtr:TPvAttrListPtr;
                    var Length:DWord):TPvErr; stdcall;

function PvAttrInfo(Camera:TPvHandle;const Name:PChar;
                    var Info:TPvAttributeInfo):TPvErr; stdcall;

function PvAttrExists(Camera:TPvHandle;const Name:PChar):TPvErr; stdcall;

function PvAttrIsAvailable(Camera:TPvHandle;const Name:PChar):TPvErr; stdcall;

function PvAttrIsValid(Camera:TPvHandle;const Name:PChar):TPvErr; stdcall;

function PvAttrRangeEnum(Camera:TPvHandle;const Name:PChar;pBuffer:PChar;
                         BufferSize:DWord;var Size:DWord):TPvErr; stdcall;

function PvAttrRangeUint32(Camera:TPvHandle;const Name:PChar;
                           var Min,Max:DWord):TPvErr; stdcall;

function PvAttrRangeFloat32(Camera:TPvHandle;const Name:PChar;var Min,Max:Single):TPvErr; stdcall;

function PvCommandRun(Camera:TPvHandle;const Name:PChar):TPvErr; stdcall;

function PvAttrStringGet(Camera:TPvHandle;const Name:PChar;Buffer:PChar;
                         BufferSize:DWord;var Size:DWord):TPvErr; stdcall;

function PvAttrStringSet(Camera:TPvHandle;const Name:PChar;
                         const Value:PChar):TPvErr; stdcall;

function PvAttrEnumGet(Camera:TPvHandle;const Name:PChar;Buffer:PChar;
                       BufferSize:DWord;var Size:DWord):TPvErr; stdcall;

function PvAttrEnumSet(Camera:TPvHandle;const Name,Value:PChar):TPvErr; stdcall;

function PvAttrUint32Get(Camera:TPvHandle;const Name:PChar;
                         var Value:DWord):TPvErr; stdcall;

function PvAttrUint32Set(Camera:TPvHandle;const Name:PChar;
                         Value:DWord):TPvErr; stdcall;

function PvAttrFloat32Get(Camera:TPvHandle;const Name:PChar;
                          var Value:Single):TPvErr; stdcall;

function PvAttrFloat32Set(Camera:TPvHandle;const Name:PChar;
                          Value:Single):TPvErr; stdcall;

procedure PvUtilityColorInterpolate(const Frame:PPvFrame;
                                    RedBuffer,GreenBuffer,BlueBuffer:Pointer;
                                    PixelPadding,LinePadding:DWord);stdcall;

implementation

const
  PvApiDLL = 'PvApi.dll';

procedure PvVersion; external pvApiDLL;
function  PvInitialize; external pvApiDLL;
procedure PvUnInitialize; external pvApiDLL;
function  PvLinkCallbackRegister; external pvApiDLL;
function  PvLinkCallbackUnRegister; external pvApiDLL;
function  PvCameraList; external pvApiDLL;
function  PvCameraCount; external pvApiDLL;
function  PvCameraInfo; external pvApiDLL;
function  PvCameraInfoByAddr; external pvApiDLL;
function  PvCameraListUnreachable; external pvApiDLL;
function  PvCameraOpen; external pvApiDLL;
function  PvCameraOpenByAddr; external pvApiDLL;
function  PvCameraClose; external pvApiDLL;
function  PvCameraIpSettingsGet; external pvApiDLL;
function  PvCameraIpSettingsChange; external pvApiDLL;
function  PvCaptureStart; external pvApiDLL;
function  PvCaptureEnd; external pvApiDLL;
function  PvCaptureQuery; external pvApiDLL;
function  PvCaptureAdjustPacketSize; external pvApiDLL;
function  PvCaptureQueueFrame; external pvApiDLL;
function  PvCaptureQueueClear; external pvApiDLL;
function  PvCaptureWaitForFrameDone; external pvApiDLL;
function  PvAttrList; external pvApiDLL;
function  PvAttrInfo; external pvApiDLL;
function  PvAttrExists; external pvApiDLL;
function  PvAttrIsAvailable; external pvApiDLL;
function  PvAttrIsValid; external pvApiDLL;
function  PvAttrRangeEnum; external pvApiDLL;
function  PvAttrRangeUint32; external pvApiDLL;
function  PvAttrRangeFloat32; external pvApiDLL;
function  PvCommandRun; external pvApiDLL;
function  PvAttrStringGet; external pvApiDLL;
function  PvAttrStringSet; external pvApiDLL;
function  PvAttrEnumGet; external pvApiDLL;
function  PvAttrEnumSet; external pvApiDLL;
function  PvAttrUint32Get; external pvApiDLL;
function  PvAttrUint32Set; external pvApiDLL;
function  PvAttrFloat32Get; external pvApiDLL;
function  PvAttrFloat32Set; external pvApiDLL;
procedure PvUtilityColorInterpolate; external pvApiDLL;

end.
