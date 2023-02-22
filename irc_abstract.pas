unit irc_abstract;
{$DEFINE JOIN}
{$DEFINE NICK_AFTER_CHAQ}
{x$DEFINE IRC_DEAD_DEBUG}
{x$DEFINE LOG_ALL_INCOMING_LINES}

{
CAP=B@Q
NICK=OHBJ
USER=TRDS
PING=QHOF
PONG=QNOF
NAMESX=O@LDRY
UHNAMES=TIO@LDR
JOIN=KNHO
PART=Q@SU
NAMES=O@LDR
CHANL=BI@OM
PRIVMSG=QSHWLRF
WHOHERE=VINIDSD
}

interface
uses
  dirfile,tickcount, commandprocessor, debug, linked_list, fatmessage,
  helpers_stream, helpers.sockets, sysutils,
  classes, stringx, managedthread, betterobject,
  typex, systemx, WatchDog,
{$IFDEF MSWINDOWS}
//  sockfix,
//  simplewinsock,
{$ENDIF}
  simpletcpconnection, simpleAutoConnection, ExceptionsX,
  idtcpclient, idglobal, multibuffermemoryfilestream,
  commandicons, better_collections;

const
  CMD_ICON_XDCC: TCommandIcon = (BitDepth: 32; RDepth:8;GDepth:8;BDepth:8;ADepth:8;Height:32;Width:32;
   data:
(
($02121313,$02121313,$02121313,$02131414,$03161717,$03131414,$02121313,$02121313,$02131414,$03161717,$03131414,$02121313,$02121313,$02131414,$03161717,$03131414,$02121313,$02121313,$02131414,$03161717,$03131414,$02121313,$02121313,$02131414,$03161717,$03131414,$02121313,$02121313,$02131414,$03161717,$03131414,$01111212),
($02121313,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$03151616),
($02121313,$04171818,$171B1C1D,$A419181B,$F4212024,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$F5201F23,$AB1D1C1F,$1C191A1A,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$03171818),
($02131414,$04181919,$A419181B,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$B41F1E21,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$03181919),
($03161717,$04151717,$F4212024,$FF201F23,$2A1C1D1E,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$2218191A,$FF212024,$F9212024,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$03151616),
($03131414,$04161717,$FF201F23,$FF212024,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$FF212024,$FF201F23,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$03151616),
($02121313,$04161717,$FF212024,$FF212024,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$FF201F23,$FF201F23,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$03151616),
($02121313,$04171818,$FF212024,$FF201F23,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$FF201F23,$FF201F23,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$03171818),
($02131414,$04181919,$FF201F23,$FF201F23,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$FF201F23,$FF212024,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$03181919),
($03161717,$04151717,$FF201F23,$FF201F23,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$FF212024,$FF212024,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$03151616),
($03131414,$04161717,$FF201F23,$FF212024,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$FF212024,$FF201F23,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$03151616),
($02121313,$04161717,$F6212024,$FF212024,$2218191A,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$1C1C1D1E,$FF201F23,$FA201F23,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$03151616),
($02121313,$04171818,$AC1F1E21,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$BA1F1E21,$17191A1A,$A519191B,$F4212024,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$F6212024,$AC1D1D20,$1C191B1B,$04161717,$03171818),
($02131414,$04181919,$1C171818,$B31C1C1F,$F9201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FA201F23,$BA1F1E22,$221C1D1E,$A519191B,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$B41D1C1F,$04171818,$03181919),
($03161717,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$FF201F23,$FF212024,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$F4212024,$FF201F23,$29141416,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$22191A1B,$FF201F23,$F9201F23,$04181919,$03151616),
($03131414,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$FF212024,$FF212024,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$FF201F23,$FF201F23,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$FF212024,$FF212024,$04151717,$03151616),
($02121313,$04161717,$04171818,$04181919,$04151717,$04161717,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$04171818,$04181919,$04151717,$04161717,$FF201F23,$FF212024,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$FF212024,$FF201F23,$04161717,$03151616),
($02121313,$04171818,$04181919,$04151717,$04161717,$04161717,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$04181919,$04151717,$04161717,$04161717,$FF212024,$FF212024,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$FF201F23,$FF201F23,$04161717,$03171818),
($02131414,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$FF212024,$FF201F23,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$FF201F23,$FF201F23,$04171818,$03181919),
($03161717,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$FF201F23,$FF201F23,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$FF201F23,$FF212024,$04181919,$03151616),
($03131414,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$FF201F23,$FF201F23,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$FF212024,$FF212024,$04151717,$03151616),
($02121313,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$4E1F2021,$A11C1C1F,$581A1B1C,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$F6201F23,$FF212024,$2219191A,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$1B1A1B1C,$FF212024,$FA201F23,$04161717,$03151616),
($02121313,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$791B1B1D,$FF201F23,$8A1D1D20,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$AC1F1E21,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$BB232326,$04161717,$03171818),
($02131414,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$7918181A,$FF201F23,$891B1B1D,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$1C171818,$B41E1E21,$F9201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$FA201F23,$BB232326,$22151617,$04171818,$03181919),
($03161717,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$791A1A1C,$FF201F23,$891B1B1D,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$FF201F23,$FF201F23,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$03151616),
($03131414,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$761D1D1F,$FF212024,$901E1E20,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$FF201F23,$FF212024,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$03151616),
($02121313,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$4D1A1B1C,$FF212024,$DC201F23,$18191A1A,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$FF201F23,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$04161717,$04171818,$04181919,$04151717,$04161717,$03151616),
($02121313,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$09171819,$CB1E1E21,$FF201F23,$E41F1E22,$A51F1F21,$A11C1C1F,$A01A1A1C,$A11D1D20,$A11E1E21,$A11E1E21,$57171819,$04151717,$04161717,$FF201F23,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$04171818,$04181919,$04151717,$04161717,$04161717,$03171818),
($02131414,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$211A1B1C,$C31C1C1F,$FF212024,$FF212024,$FF201F23,$FF201F23,$FF201F23,$FF212024,$FF212024,$8A1E1E20,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$03181919),
($03161717,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171919,$3D1A1B1C,$601C1D1E,$621A1A1C,$6218181A,$621A1A1C,$621C1D1F,$621D1D1F,$35151516,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$03151616),
($03131414,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$04161717,$04161717,$04171818,$04181919,$04151717,$03151616),
($01111212,$03151616,$03171818,$03181919,$03151616,$03151616,$03151616,$03171818,$03181919,$03151616,$03151616,$03151616,$03171818,$03181919,$03151616,$03151616,$03151616,$03171818,$03181919,$03151616,$03151616,$03151616,$03171818,$03181919,$03151616,$03151616,$03151616,$03171818,$03181919,$03151616,$03151616,$03151616)
 ));

const
  DEFAULT_SERVER = '';
  DEFAULT_PORT = 6667;
  DEFAULT_NICK = 'nightman';
  default_USER = 'night@man';
  default_gecos = 'google.com';
type
  TLocalFileStream = TFileStream;
{$IFDEF NO_CTO_PROXY}
  TLocalBaseConnection = TSimpleTCPConnection;
{$ELSE}
  TLocalBaseConnection = TSimpleAutoConnection;
{$ENDIF}

  TOnCommandMethod = function (swhoFrom, sOriginalLine, sCmd: string;
  params: TStringList): boolean of object;

  TLocalSocketclient = class(TLocalBaseConnection)
  public
    Scrambled: boolean;
    function ScrambleString(s: string): string;
    function UnScrambleString(s: string): string;
    function SendScrambledLine(sLine: string): string;
    function ReadSCrambledLn(out sLine: string; iTimeout: nativeint): boolean;

  end;


  TChatMultiUserClient = class;//forward
  TChatConversation= class;//forward

  TChatClientState = (irccsNotStarted, irccsStarting, irccsStarted, irccsStopping, irccsStopped);

  TXDCCCommand = class(TCommand)
  protected
    procedure DoExecute; override;
    procedure InitExpense;override;

  public
    skipped: boolean;
    irc: TChatMultiUserClient;
    trackingnumber: int64;
    ip: string;
    port: int64;
    localfile: string;
    size: int64;
    loser: string;
    pack: ni;
    lastnotify: ticker;
    pendingresume: boolean;
    resumeaccepted: boolean;
    procedure Init; override;
  end;


  TPack = record
    assid: int64;
    loser: string;
    pack: ni;
    filename: string;
    size: int64;
    channel: string;
    function Idiot: string;
    function TempFileName: string;
  end;

  TFoundPackEvent = procedure (sender: TObject; pack: TPack) of object;
  TXDCCEvent = procedure (c: TXDCCCommand) of object;
  TChatEvent = procedure (sender: TChatMultiUserClient) of object;
  TDCCAssErrorEvent = procedure (assid: int64; error: string) of object;
  TChatDMEvent = procedure (sender: TChatMultiUserClient; loser: string; dm: string; dirout: boolean) of object;
  TChatConversationEvent = procedure (sender: TChatConversation; sFrom, sMessage: string) of object;

  TEmptyEvent = procedure of object;

  TChatConversation = class(TSharedObject)
  private
    FIgnoreExcl: boolean;
    FOnUserEntersRoom: TProc<string>;
  protected
    FOnLineReceived: TChatConversationEvent;
    FonChatReceived: TChatConversationEvent;
    FLines: TStringlist;
    FUsers: TStringList;
    FpmHold: string;
    procedure RawLineReceived(sfrom, sMessage: string);
    procedure ChatReceived(sFrom, sMessage: string);
    function handle_Command(sOriginalLine: string; sWho, sCmd_lowercase: string; params: TStringlist): boolean;//return TRUE if handled
    function default_handle_Command(sOriginalLine: string; sWho, sCmd_lowercase: string; params: TStringlist): boolean;//return TRUE if handled
    function default_handle_command_privmsg(sOriginalLine: string; sWho, sCmd_lowercase: string; params: TStringlist): boolean;//return TRUE if handled
    function handle_command_names(sOriginalLine: string; sWho, sCmd_lowercase: string; params: TStringlist): boolean;//return TRUE if handled
  public
    CommandTrigger: string;
    channel: string;
    irc: TChatMultiUserClient;
    fOnCommand: TOnCommandMethod;
    fPeriodically: TProc;
    OnPeriodically: TEmptyEvent;
    procedure PrivMsg(s: string);
    procedure PM(s: string);
    procedure PMMultiLine(s: string);
    procedure PMHold(s: string);
    procedure PMCon(sExpression: string);
    procedure PMConLn(sExpression: string);
    procedure Part;
    procedure inviteUser(user: string);

    function LinesAvailable: string;
    function ReadLn: string;
    constructor Create; override;
    procedure Detach; override;
    property OnLineReceived: TChatConversationEvent read FOnLineReceived write FOnLineReceived;
    property OnChatReceived: TChatConversationEvent read FOnChatReceived write FOnChatReceived;
    procedure UserJoined(sUser: string);
    procedure UserLeft(sUser: string);
    function GetUsers:IHolder<TStringList>;
    property OnUserEntersRoom: TProc<string> read FOnUserEntersRoom write FOnUserEntersRoom;

    property IgnoreExcl: boolean read FIgnoreExcl write FIgnoreExcl;

  end;


  TChatMultiUserClient = class(TSharedObject)
  private
    FOnInvite: TProc<string>;
    FonFoundPack: TFoundPackEvent;
    FOnFinishXDCC: TXDCCEvent;
    FOnStartXDCC: TXDCCEvent;
    FOnPoll: TChatEvent;
    FOnXDCCProgress: TXDCCEvent;
    FOnDM: TChatDMEvent;
    FOnAssError: TDCCAssErrorEvent;
    FConversations: TSharedList<TChatConversation>;
    FEndedConversations: TArray<IHolder<TChatConversation>>;
    FChannels: TStringlist;
    FState: TChatClientState;
    function GetConversation(idx: ni): TChatConversation;

  strict protected
    procedure CleanupEndedConversations;
    procedure AcceptResume(loser, filename, port: string);
    function HasXDCCAlready(loser, filename: string): boolean;
    procedure StartXDCC(assid: int64; loser: string; pack: ni; filename, ip, port: string; size: int64 = 0);
    procedure TrackUnstartedPack(p: TPack);
    procedure UntrackUnstartedPack(loser: string; pack: ni);
    procedure RejoinConversations;
  public
    tmLastPeriodicCheck: ticker;
    cli: TLocalSocketClient;
    host: string;
    port: ni;
    thr: TExternalEventThread;
    xdccs: TCommandList<TXDCCCommand>;
    unstartedpacks: array of TPack;
    online: boolean;
    nick: string;
    user: string;
    tmSeen: ticker;
    tmLastXDCCCheck: ticker;
    constructor Create; override;
    procedure Start;
    procedure Stop;
    procedure Detach; override;
    procedure Connect;
    procedure Disconnect;

    procedure join(sChannel: string);
    procedure invite(room, who: string);
    procedure joinDM(sWith: string);
    procedure CheckPeriodically;
    function ShouldEncrypt: boolean;virtual;
    procedure DoWatchDogReset;virtual;

    procedure IRCExecuteClientThreadForAllChannels(thr: TExternalEventThread);
    procedure IRCSend(sLine: string);
    procedure IRCUserSend(sLine: string);
    procedure handle_line(sLine: string);
    procedure handle_command(originalline: string; parsed: TStringList; oobs: TStringList);
    procedure handle_join(originalline: string; parsed: TStringList; oobs: TStringList);
    procedure handle_part(originalline: string; parsed: TStringList; oobs: TStringList);
    procedure handle_whohere(originalline: string; parsed: TStringList; oobs: TStringList);
    function handle_conversation_privmsg(from, target, line: string): boolean;
    procedure handle_pack(parsed: TStringList; oobs: TStringlist; channel: string);
    function GetUnstartedPackFromLoser(loser: string; filename: string): TPack;
    function RequestPack(assid: int64; loser: string; pack: ni; filename: string): boolean;
    function CancelPack(assid: int64): boolean;
    procedure CheckXDCCs;
    procedure FoundPack(p: TPack);
    property onFoundPack: TFoundPackEvent read FonFoundPack write FOnFoundPack;
    property onStartXDCC: TXDCCEvent read FOnStartXDCC write FOnStartXDCC;
    property OnFinishXDCC: TXDCCEvent read FOnFinishXDCC write FOnFinishXDCC;
    property OnXDCCProgress: TXDCCEvent read FOnXDCCProgress write FOnXDCCProgress;
    property OnAssError: TDCCAssErrorEvent read FOnAssError write FOnAssError;
    property OnPoll: TChatEvent read FOnPoll write FOnPoll;
    property OnDM: TChatDMEvent read FOnDM write FOnDM;
    procedure AssError(assid: int64; s: string);
    procedure OnConnect;virtual;
    property OnInvite: Tproc<string> read FOnInvite write FOnInvite;

    function NewConversation(channel: string): IHolder<TChatConversation>;
    procedure EndConversation(conv: IHolder<TChatConversation>);
    procedure Privmsg(sTarget, sMessage: string);
    function FullIdent: string;
    function FindConversation(sChannel: string): TChatConversation;
    property Conversations[idx: ni]: TChatConversation read GetConversation;
    function ConversationCount: ni;
    procedure ChatCommand(s: string);overload;
    procedure ChatCommand(cmd: string; params: TStringlist);overload;
    function GetChannels: IHolder<TStringList>;
    procedure RequestChannels;
    procedure Part(sChannel: string);
    property State: TChatClientState read FState write FState;
    function WaitForState(s: TChatClientState; iTimeout: ni = 8000): boolean;
  end;





function getuser(sParam: string): string;
function DecodeIP(sIntIP: string): string;
function cleanLoser(loser: string): string;
function StripString(s: string): string;
procedure locallog(s: string);

function GeTChatAutoNick(bot: boolean): string;

implementation

function GeTChatAutoNick(bot: boolean): string;
begin
  if bot then begin
    var c := GetComputerName;
    c := stringreplace(c, '''','', [rfReplaceAll]);
    c := stringreplace(c, #$2019,'', [rfReplaceAll]);
    c := stringreplace(c, '"','', [rfReplaceAll]);
    c := stringreplace(c, ' ','', [rfReplaceAll]);
    var d := extractfilenamepart(dllname);
    d := stringreplace(d, '''','', [rfReplaceAll]);
    d := stringreplace(d, '"','', [rfReplaceAll]);
    d := stringreplace(d, ' ','', [rfReplaceAll]);

    result := d+'-'+c
  end else begin
    var c := GetComputerName;
    var r := '';
    SplitString(c,#$2019, c,r);
    c := stringreplace(c, '''','', [rfReplaceAll]);
    c := stringreplace(c, #$2019,'', [rfReplaceAll]);
    c := stringreplace(c, '"','', [rfReplaceAll]);
    c := stringreplace(c, ' ','', [rfReplaceAll]);
    result := c;
  end;

end;

function GeTChatAutoIdent(bot: boolean): string;
begin
  var c := GetComputerName;
  c := stringreplace(c, '''','', [rfReplaceAll]);
  c := stringreplace(c, #$2019,'', [rfReplaceAll]);
  c := stringreplace(c, '"','', [rfReplaceAll]);
  c := stringreplace(c, ' ','', [rfReplaceAll]);
  var d := extractfilenamepart(dllname);
  d := stringreplace(d, '''','', [rfReplaceAll]);
  d := stringreplace(d, '"','', [rfReplaceAll]);
  d := stringreplace(d, ' ','', [rfReplaceAll]);

  result := d+'-'+c+inttostr(TThread.Current.threadid);
end;

procedure locallog(s: string);
begin
//  exit;
{$IFDEF LOG_TO_IRC}
  if not logging then
{$ENDIF}
    Debug.log(s);
end;

function StripString(s: string): string;
var
  l,r: string;
begin
  s := stringreplace(s, #$02, '', [rfReplaceAll]);//bold
  s := stringreplace(s, #$1D, '', [rfReplaceAll]);//italics
  s := stringreplace(s, #$1F, '', [rfReplaceAll]);//italics
  s := stringreplace(s, #$16, '', [rfReplaceAll]);//italics
  s := stringreplace(s, #$0F, '', [rfReplaceAll]);//italics
  while SplitString(s, #$03, l,r) do begin
    if zcopy(r,2,1) = ',' then begin
      r := zcopy(r, 5,length(r));
    end else begin
      r := zcopy(r, 2,length(r));
    end;

    //also replace just one 0x03 following
    r := stringreplace(r, #$03,'',[]);
    s := l + r;

  end;

  result := s;




end;

{ TChatMultiUserClient }

function cleanLoser(loser: string): string;
begin
  var junk: string;
  result := loser;
  SplitString(result, '!', result, junk);
  if result = '' then
    exit;
  if result[low(result)] = ':' then begin
    result := stringreplace(result, ':', '', []);//replaces only first :
  end;


end;

function Cleanup(s: string): string;
begin
  result := s;
  result := stringreplace(result, #2, '', [rfReplaceAll]);
  result := stringreplace(result, #1, '', [rfReplaceAll]);
  result := stringreplace(result, ':', '', [rfReplaceAll]);
  result := stringreplace(result, '[', '', [rfReplaceAll]);
  result := stringreplace(result, ']', '', [rfReplaceAll]);

end;

function InterpretSize(s: string): int64;
var
  multiplier: int64;
begin
  s := trimstr(s);
  if s = '' then
    exit(0);
  multiplier := 1;

  var mstr := uppercase(s[high(s)]);
  if mstr = 'G' then
    multiplier := BILLION;
  if mstr = 'M' then
    multiplier := MILLION;
  if mstr = 'K' then
    multiplier := KILO;

  var sz := copy(s, STRZ, length(s)-1);

  if not isFloat(sz) then
    exit(0);

  var f : double := strtofloat(sz);
  result := round(f*multiplier);

end;
function DecodeIP(sIntIP: string): string;
begin
  var i: int64 := strtoint64(sIntIP);
  result := ((i shr 24) and 255).tostring+'.'+
            ((i shr 16) and 255).tostring+'.'+
            ((i shr 8) and 255).tostring+'.'+
            ((i shr 0) and 255).tostring;

end;

function getuser(sParam: string): string;
var
  junk: string;
begin
  if length(sParam) < 1 then
    exit('');

  if sParam[strz] = ':' then
    sParam := copy(sParam, strz+1, length(sParam));

  SplitString(sParam, '!', result, junk);
end;


procedure TChatMultiUserClient.AcceptResume(loser, filename, port: string);
begin
  for var t := 0 to xdccs.count-1 do begin
    var dcc := xdccs[t];
    if (dcc.loser = loser) and (dcc.port.tostring=port) then begin
      dcc.resumeaccepted := true;
    end;

  end;

end;

procedure TChatMultiUserClient.AssError(assid: int64; s: string);
begin
  if assigned(FOnAssError) then
    FOnAssError(assid, s);
end;

function TChatMultiUserClient.CancelPack(assid: int64): boolean;
begin
  result := false;
  for var t := 0 to high(unstartedpacks) do begin
    if unstartedpacks[t].assid=assid then begin
      UntrackUnstartedPack(unstartedpacks[t].loser, unstartedpacks[t].pack);
      exit(true);
    end;
  end;

end;

procedure TChatMultiUserClient.ChatCommand(cmd: string; params: TStringlist);
begin
  cmd := uppercase(cmd);
  if cmd='/JOIN' then begin
    if params.count > 0 then
      self.join(params[0]);
  end;

end;

procedure TChatMultiUserClient.CheckPeriodically;
begin
  if gettimesince(tmLastPeriodicCheck) < 10000 then
    exit;
  Lock;
  try
    for var t:= ConversationCount-1 downto 0 do begin
      if t > (conversationcount-1) then
        continue;

      if assigned(conversations[t].OnPeriodically) then begin
        conversations[t].OnPeriodically;
      end;

      if assigned(conversations[t].fPeriodically) then begin
        conversations[t].fPeriodically();
      end;
    end;
    tmLastPeriodicCheck := getticker;
  finally
    Unlock;
  end;
end;

procedure TChatMultiUserClient.CheckXDCCs;
begin
  tmLastXDCCCheck := GetTicker;
  for var t:= xdccs.Count-1 downto 0 do begin
    if xdccs[t].IsComplete or xdccs[t].skipped then begin
      var c := xdccs[t];
      if c.Errormessage <> '' then begin
        AssError(c.trackingnumber, extractfilename(c.localfile)+' failed with:'+c.ErrorMessage);

      end;
//      else begin
        xdccs.delete(t);
        c.raiseexceptions := false;
        if not c.skipped then
          c.WaitFor;
        if assigned(OnFinishXDCC) then
          OnFinishXDCC(c);
        c.Free;
        c := nil;
//      end;
    end;
  end;
end;

procedure TChatMultiUserClient.CleanupEndedConversations;
begin
//  var l := locki;
  lock;
  try
  for var t:=0 to high(FEndedConversations) do begin
    FConversations.Remove(FEndedConversations[t].o);
  end;
  Setlength(FendedConversations,0);

  finally
    Unlock;
  end;
end;

procedure TChatMultiUserClient.Connect;
var
  sConn: string;
begin
  if cli <> nil then
    exit;

  state := irccsStarting;

  online := false;
  cli := TLocalSocketClient.create;
  cli.HostName := host;
  cli.Endpoint := inttostr(port);
  cli.Connect;
  IRCSend('OBFS');
  cli.scrambled := true;
  IRCSend('CHAL');
{$IFNDEF NICK_AFTER_CHAQ}
  IRCSend('USER '+nick);
  IRCSEnd('NICK '+user+' * 8 :'+default_gecos);
{$ENDIF}

end;

function TChatMultiUserClient.ConversationCount: ni;
begin
//  var l := self.LockI;
  lock;
  try
    result := FConversations.Count;

  finally
    Unlock;
  end;
end;

constructor TChatMultiUserClient.Create;
begin
  inherited;
  tmSeen := GetTicker;
  FChannels := TStringlist.create;
  xdccs := TcommandList<TXDCCCommand>.create;
  FConversations := TSharedList<TChatConversation>.create;
  host := DEFAULT_SERVER;
  port := DEFAULT_PORT;
  nick := GeTChatAutoNick(true);
  user := GeTChatAutoIdent(true);


end;

procedure TChatMultiUserClient.Detach;
begin
  if detached then exit;
  Stop;
  Disconnect;//kills cli


  xdccs.WaitForAll_DestroyWhileWaiting;

  FConversations.Free;
  FConversations := nil;
  xdccs.free;
  xdccs := nil;
  FChannels.free;
  FChannels := nil;

  inherited;
end;

procedure TChatMultiUserClient.Disconnect;
begin
  State := irccsStopping;
  if cli = nil then
    exit;
  cli.Disconnect;
  cli.Free;
  cli := nil;
  State := irccsStopped;
end;

procedure TChatMultiUserClient.DoWatchDogReset;
begin
  //
end;

procedure TChatMultiUserClient.EndConversation(conv: IHolder<TChatConversation>);
begin
//  var l := LockI;
  lock;
  try
  setlength(FEndedConversations, length(FEndedConversations)+1);
  FEndedConversations[high(FEndedConversations)] := conv;

  finally
    Unlock;
  end;

end;

function TChatMultiUserClient.FindConversation(
  sChannel: string): TChatConversation;
begin
//  var l := FConversations.LockI;
  Lock;
  try
    for var t := 0 to FConversations.count-1 do begin
      if comparetext(Fconversations[t].channel,sChannel)=0 then
        exit(FConversations[t]);
    end;
    result := nil;
  finally
    unlock;
  end;

end;

procedure TChatMultiUserClient.FoundPack(p: TPack);
begin
  if assigned(onFoundPack) then
    onFoundPack(self, p);
end;

function TChatMultiUserClient.FullIdent: string;
begin
  result := nick+'!'+user;
end;

function TChatMultiUserClient.GetChannels: IHolder<TStringList>;
begin
  result := StringToStringListH('');
//  var l := self.LockI;
  lock;
  try
    for var t:= 0 to FChannels.count-1 do begin
      result.o.add(FChannels[t]);
    end;

  finally
    Unlock;
  end;
end;

function TChatMultiUserClient.GetConversation(idx: ni): TChatConversation;
begin
//  var l := self.LockI;
  try
    Lock;
  result := FConversations[idx];
  finally
    Unlock;
  end;
end;

function TChatMultiUserClient.GetUnstartedPackFromLoser(loser: string; filename: string): TPack;
begin
  loser := getuser(loser);
  result.pack := -1;
  result.assid := -1;
  for var t:= 0 to High(unstartedpacks) do begin
    if (comparetext(unstartedpacks[t].loser,loser)=0)
    and (comparetext(unstartedpacks[t].filename, filename)=0)
    then
      exit(unstartedpacks[t]);
  end;
end;

procedure TChatMultiUserClient.handle_command(originalline: string; parsed, oobs: TStringList);
var
  pp:TPack;
begin
  if parsed.count < 2 then
    exit;
  var cmd := parsed[0];
  var sFrom := '';
  if zcopy(cmd,0,1) = ':' then begin
    sFrom := cmd;
    cmd := parsed[1];
  end;
  if comparetext(cmd,'INVITE')=0 then begin
    Lock;
    try
//      NewConversation(PARSED[2]);
      if assigned(FOnInvite) then
        FOninvite(PARSED[2]);
    finally
      Unlock;
    end;
  end else
  if comparetext(cmd,'PING')=0 then begin
    IRCSend('PONG ' + parsed[1]);
  end else
  if comparetext(cmd,'CHAQ')=0 then begin
    IRCSend('CHAR '+DifferentOb(SimpleOb(zcopy(originalline, 5,length(originalline)))));
    {$IFDEF NICK_AFTER_CHAQ}
      IRCSend('NICK '+nick);
      IRCSEnd('USER '+user+' * 8 :'+default_gecos);
    {$ENDIF}

  end else
  if comparetext(cmd,'CHANL')=0 then begin
    begin
//      var l := Locki;
      try
        Lock;
        FChannels.clear;
        for var t := 1 to parsed.Count-1 do begin
          var c := parsed[t];
          if trim(c) <> '' then
            FChannels.add(parsed[t]);
        end;
      finally
        Unlock;
      end;
    end;
    MMQ.QuickBroadcast('ChannelsUpdated');
  end else
  if comparetext(cmd,'JOIN')=0 then begin
    handle_join(originalline, parsed, oobs);
  end else
  if comparetext(cmd,'PART')=0 then begin
    handle_part(originalline, parsed, oobs);
  end else
  if comparetext(cmd,'WHOHERE')=0 then begin
    handle_whohere(originalline, parsed, oobs);
  end else
  if comparetext(cmd,'OBFS')=0 then begin
//    cli.SendScrambledLine('OBFS');
//    cli.Scrambled := true;
  end;


  if (comparetext(parsed[0], '376')=0)
   or (comparetext(parsed[0], '422')=0)
  or (comparetext(parsed[1], '376')=0)
  or (comparetext(parsed[1], '422')=0) then begin

  end;

  if comparetext(parsed[0],'NOTICE')=0 then begin
    state := irccsStarted;
    OnConnect;//connected -- maybe join some default channels?!
    online := true;
  end;

  if parsed.count < 4 then exit;

  if (comparetext(parsed[1],'privmsg')=0) then begin
    var target := parsed[2];

    var from := parsed[0];
    var line := parsed[3];
    for var t:= 4 to parsed.count-1 do begin
      line := line + ' '+parsed[t];
    end;

    if handle_conversation_privmsg(from, target, line) then begin

    end else
    if (comparetext(parsed[2],nick)=0) then begin
      var frohm := GetUser(parsed[0]);
      if assigned(OnDM) then begin
        var l,r: string;
        SplitStringNoCase(originalline, 'PRIVMSG', l,r);
        onDM(self, frohm, r, false);
      end;
      if comparetext(parsed[3],':')=0 then begin
        if comparetext(oobs[0],'DCC')=0 then begin
          if comparetext(oobs[1],'SEND')=0 then begin
            var junk: string;
            var sFile := oobs[2];
            var intip := oobs[3];
            var decodedip := decodeip(intip);
            var port := oobs[4];
            var size :int64 := 0;
            if oobs.count>5 then
              size := strtoint64(oobs[5]);

            //is this a duplicate message?
            if not HasXDCCAlready(frohm, sFile) then begin
              //is this something we requested?
              pp := getunstartedpackfromloser(frohm,sFile);
              if pp.assid >=0 then
                StartXDCC(pp.assid, frohm, pp.pack, sFile, decodedip, port, size);
            end;
          end;
          if comparetext(oobs[1],'ACCEPT')=0 then begin
            var sFile := oobs[2];
            var port := oobs[3];
            var position := oobs[4];
            AcceptResume(frohm, sfile, port);
          end;
        end;
      end;
{$IFDEF LOG_TO_IRC}
      if not logging then
{$ENDIF}
        locallog(parsed[3]);

    end;
  end;

end;

function TChatMultiUserClient.handle_conversation_privmsg(from, target, line: string): boolean;
begin
  result := false;
//  var l := FConversations.LockI;
  Lock;
  try

    for var t := FConversations.count-1 downto 0 do begin
      if t < FConversations.count then
      if comparetext(FConversations[t].channel, target) = 0 then begin
        if zcopy(from, 0,1) = ':' then
          from := zcopy(from, 1,length(from));

        if zcopy(line, 0,1) = ':' then
          line := zcopy(line, 1,length(line));

        FConversations[t].RawLineReceived(from, line);
        result := true;
      end;
    end;
  finally
    Unlock;
  end;



end;

procedure TChatMultiUserClient.handle_join(originalline: string; parsed,
  oobs: TStringList);
begin
  if parsed.count < 3 then
    exit;

  var sChannel := parsed[2];
  var swho := parsed[0];
  sWho := GetUser(sWho);

  var conv := FindConversation(sChannel);
  if conv <> nil then begin
    conv.UserJoined(sWho);
  end;
end;

procedure TChatMultiUserClient.handle_line(sLine: string);
var
  l,r: string;
  oob: string;
begin
  sLine := StripString(sLine);
  //locallog(sLine);
  if SplitString(sLine, #01, l,r) then begin
    oob := r;
    splitstring(oob, #01, oob, r);
  end;

  var oobs : IHolder<TStringList>:= ParseStringh(oob, ' ');
  var sll := ParseStringh(l, ' ');
  var slr := ParseStringh(r,' ');
  sll.o.Add(oob);
  sll.o.AddStrings(slr.o);
  handle_command(sLine, sll.o, oobs.o);
  CheckPeriodically;
end;

procedure TChatMultiUserClient.handle_pack(parsed, oobs: TStringlist; channel: string);
var
  p: TPack;
begin
  try
  for var t:= parsed.count-1 downto 0 do
    if parsed[t] = '' then
      parsed.delete(t);

  var pack := cleanup(parsed[3]);
  var size := cleanup(parsed[parsed.count-2]);
  var filename := trim(parsed[parsed.count-1]);
  filename := stringreplace(filename, #1, '', [rfReplaceAll]);
  filename := stringreplace(filename, #0, '', [rfReplaceAll]);

  p.loser := getuser(parsed[0]);
  var pstr := copy(pack,strz+1,length(pack));
  if IsInteger(pstr) then begin
    p.pack := strtoint64(pstr);
  end else begin
    exit;
  end;
  p.filename := filename;
  p.size := interpretsize(size);
  p.channel := channel;
  FoundPack(p);
  except
  end;

end;

procedure TChatMultiUserClient.handle_part(originalline: string; parsed,
  oobs: TStringList);
begin
  if parsed.count < 3 then
    exit;

  var sChannel := parsed[2];
  var swho := parsed[0];
  sWho := GetUser(sWho);

  var conv := FindConversation(sChannel);
  if conv <> nil then begin
    conv.UserLeft(sWho);
  end;
end;

procedure TChatMultiUserClient.handle_whohere(originalline: string; parsed,
  oobs: TStringList);
begin
  if parsed.count < 3 then
    exit;

  var sChannel := parsed[2];
  var conv := FindConversation(sChannel);
  if conv <> nil then begin
    for var t := 3 to parsed.count-1 do begin
      var whodis := parsed[t];
      if trim(whodis) <> '' then
        conv.UserJoined(parsed[t]);
    end;
  end;
end;

function TChatMultiUserClient.HasXDCCAlready(loser, filename: string): boolean;
begin
  result := false;
  for var t := 0 to xdccs.count-1 do begin
    var dcc := xdccs[t];
    if (dcc.loser = loser) and (comparetext(extractfilename(dcc.localfile),filename)=0) then begin
      exit(true);
    end;

  end;

end;

procedure TChatMultiUserClient.invite(room, who: string);
begin
  if who = '' then
    Debug.Log('invalid who');

  IRCSend('INVITE '+who+' '+room);//join
  IRCSend(SimpleOb('QSHWLRF')+' '+Who+' :INVITE '+room);//privmsg

end;

procedure TChatMultiUserClient.IRCExecuteClientThreadForAllChannels(thr: TExternalEventThread);
begin

  try
  thr.Name := 'TChatMultiUserClient.IRCExecute';
  Connect;//if not already connected
{$IFDEF IRC_DEAD_DEBUG}
  Debug.Log('---->waiting for data<----');
{$ENDIF}
  var sLine: string;
                                //v properly raises exception if connection broken
  if (cli.WaitForData(8000) and (cli.ReadSCrambledLn(sLine,8000))) then begin
    tmSeen := getticker;
    WD.Reset;
    DoWatchDogReset;


    if sLine <> '' then begin
//      locallog(sLine);
        if zpos(SimpleOb('UR '), sLine)=0 then begin//CHANL
          var slh := ParseStringh(sline, ' ');
          self.nick := slh.o[slh.o.count-1];

        end;
{$IFDEF LOG_ALL_INCOMING_LINES}
        if zpos(SimpleOb('BI@OM'), sLine)>=0 then begin//CHANL
          Debug.Log('<<'+SimpleOb('BI@OM')+' not logged to protect privacy'); //chanl
        end else
        if zpos(SimpleOb('Q@SU')+' ', sLine)>=0 then begin   //PART
          Debug.Log('<<'+SimpleOb('Q@SU')+' not logged to protect privacy');
        end else
        if zpos(SimpleOb('KNHO')+' ', sLine)>=0 then begin//JOIN
          Debug.Log('<<'+SimpleOb('KNHO')+' not logged to protect privacy');
        end else
          Debug.Log('<<'+sLine);
{$ENDIF}
        Handle_Line(sLine);
{$IFDEF LOG_ALL_INCOMING_LINES}
//        if zpos('CHANL', sLine)<0 then
//        Debug.Log('<<<<'+sLine);
{$ENDIF}
    end else begin
      Debug.Log('Got a blank line, disconnected?');
      Debug.Log('Disconnecting client');
      cli.disconnect;
      Debug.Log('Reconnecting client');
      connect;
      if cli.Connected then begin
        Debug.Log('Client reconnected');
      end else begin
        Debug.Log('Client failed to reconnect');
        exit;
      end;

    end;
  end else begin
{$IFDEF IRC_DEAD_DEBUG}
    DebuSg.Log('No data in channels.');
{$ENDIF}
    CheckPeriodically;
    if gettimesince(tmSeen) > 350000 then begin
      Debug.log('We haven''t seen any data (including pings) in a while');
      Debug.Log('disconnecting');
      cli.disconnect;
      tmSeen := GetTicker-(300000);
      cli.Free;
      cli := nil;
      Connect;
      exit;
    end;
  end;

  if gettimesince(tmLastXDCCcheck) > 2000 then
    CheckXDCCs;

  if online then
    if assigned(FOnPoll) then
      FOnPoll(self);

  except
    on e: exception do begin
      thr.status := e.message;
      Disconnect;
      sleep(1000);

    end;
  end;
end;

procedure TChatMultiUserClient.IRCSend(sLine: string);
begin
  lock;
  try

    if (cli <> nil) and (cli.connected) then begin
      locallog('>>'+sLine);
      cli.SendScrambledLine(sLine);
      locallog('>>>>'+sLine);

    end;
  finally
    Unlock;
  end;

end;

procedure TChatMultiUserClient.IRCUserSend(sLine: string);
begin
  IRCSend(':'+fullident+' '+sline);
end;

procedure TChatMultiUserClient.join(sChannel: string);
begin
//  var l := self.LockI;
  Lock;
  try
    IRCSend(SimpleOb('KNHO')+' '+sChannel);//join
    IRCSend('WHOHERE '+sChannel);
  finally
    Unlock;
  end;
end;

procedure TChatMultiUserClient.joinDM(sWith: string);
begin
  var room := 'DM-'+nick+'-'+sWith;
  join('DM-'+nick+'-'+sWith);
  invite(sWith, room);


end;

function TChatMultiUserClient.NewConversation(
  channel: string): IHolder<TChatConversation>;
begin
  result := THolder<TChatConversation>.create;
  result.o := TChatConversation.create;
  result.o.irc := self;
  result.o.channel := channel;
  FConversations.Add(result.o);
  if assigned(cli) and cli.connected and self.online then
    join(result.o.channel);

end;

procedure TChatMultiUserClient.OnConnect;
begin
  RejoinConversations;
  //no implementation requied, but you might want to join some default channels or something
end;

procedure TChatMultiUserClient.Privmsg(sTarget, sMessage: string);
begin
  IRCSend(SimpleOb('QSHWLRF')+' '+sTarget+' :'+sMessage);//privmsg
end;

procedure TChatMultiUserClient.Part(sChannel: string);
begin
  Lock;
  try
    var c  := FindConversation(sChannel);
    if c <> nil then begin
      FConversations.Remove(c);
//      c.free;
    end;


  finally
    Unlock;
  end;
  IRCSend(SimpleOb('Q@SU')+' '+sChannel);

end;

procedure TChatMultiUserClient.RejoinConversations;
begin
//  var l := FConversations.Locki;
  Lock;
  try
    for var t := 0 to FConversations.count-1 do begin
      join(FConversations[t].channel);
    end;
  finally
    Unlock;
  end;


end;

procedure TChatMultiUserClient.RequestChannels;
begin
  IRCSend('CHANL');
end;

function TChatMultiUserClient.RequestPack(assid: int64; loser: string; pack: ni; filename: string): boolean;
var
  p: TPack;
begin
  result := false;
  if not online then exit;

  if GetUnstartedPackFromLoser(loser,filename).pack >= 0  then
    exit(false);
//  var l : ILock := LockI;
  Lock;
  try


    var msg := 'xdcc send #'+pack.tostring;
    IRCSend('PRIVMSG '+loser+' '+msg);
    if assigned(OnDM) then
      OnDM(self, loser, msg, true);

    p.loser := loser;
    p.pack := pack;
    p.filename := filename;
    p.size := 0;
    p.assid := assid;
    TrackUnstartedPack(p);

    exit(true);
  finally
    Unlock;
  end;

end;

function TChatMultiUserClient.ShouldEncrypt: boolean;
begin
  result := false;
end;

procedure TChatMultiUserClient.Start;
begin
  if nick = '' then
    raise ECritical.create('you cannot start client without a nick');

  thr :=  TPM.Needthread<TExternalEventThread>(nil);
  thr.OnExecute := self.IRCExecuteClientThreadForAllChannels;
  thr.Loop := true;
  thr.RunHot := true;
  thr.HasWork := true;
  thr.beginstart;
end;

procedure TChatMultiUserClient.StartXDCC(assid: int64; loser: string; pack: ni; filename, ip, port: string; size: int64=0);
var
  p: Tpack;
begin


  var cmd := TXDCCCommand.create;
  cmd.irc :=self;

  p.loser := getuser(loser);
  p.pack := pack;
  p.filename := filename;

  cmd.trackingnumber := assid;
  cmd.localfile := p.TempFileName;
  cmd.ip := ip;
  cmd.port := strtoint64(port);
  cmd.size := size;
  cmd.loser := loser;
  cmd.pack := pack;

  if fileexists(cmd.localfile) then begin
    var sz: int64 := getfilesize(p.tempfilename);
    if size < sz then
        deletefile(p.tempfilename)
    else if sz=size then begin
      cmd.skipped := true;
      xdccs.Add(cmd);
      UntrackUnstartedPack(cmd.loser, cmd.pack);
      exit;
    end;

    cmd.pendingresume := true;
                     //PRIVMSG                            //DCC               //RESUME
    var s := SimpleOb('QSHWLRF')+' '+loser+' :'#1+SimpleOb('EBB')+' '+SimpleOb('SDRTLD')+' '+p.filename+' '+port+' '+sz.tostring+#1;
    IRCSend(s);
    onDM(self, loser, s , false);
  end;


  if assigned(onStartXDCC) then
    onStartXDCC(cmd);
  xdccs.Add(cmd);
  cmd.start;
  UntrackUnstartedPack(cmd.loser, cmd.pack);

end;

procedure TChatMultiUserClient.Stop;
begin
  if thr = nil then
    exit;

  if assigned(cli) then
    cli.Disconnect;

  thr.EndStart;
  thr.Stop;

  TPM.NoNeedthread(thr);
  thr := nil;


end;

procedure TChatMultiUserClient.TrackUnstartedPack(p: TPack);
begin
//  var l : ILock := locki;
  Lock;
  try
    setlength(unstartedpacks, length(unstartedpacks)+1);
    unstartedpacks[high(unstartedpacks)] := p;
  finally
    Unlock;
  end;
end;

procedure TChatMultiUserClient.UntrackUnstartedPack(loser: string; pack: ni);
begin
//  var l : ILock := locki;
  Lock;
  try
    var del:ni := -1;
    for var t := high(unstartedpacks) downto 0 do begin
      if (unstartedpacks[t].loser = loser)
      and (unstartedpacks[t].pack = pack) then begin
        del := t;
      end;
    end;

    if del >= 0 then begin
      for var t := del to high(unstartedpacks)-1 do
        unstartedpacks[t] := unstartedpacks[t+1];

      setlength(unstartedpacks, length(unstartedpacks)-1);
    end;
  finally
    Unlock;
  end;


end;

function TChatMultiUserClient.WaitForState(s: TChatClientState;
  iTimeout: ni): boolean;
begin
  var tmStart: ticker := GetTicker;
  while not (State = s) do begin
    sleep(100);
    if gettimesince(tmStart) > iTimeout then
      exit(false);
  end;
  result := true;
end;

{ TXDCCCommand }

procedure TXDCCCommand.DoExecute;
var
  a: array[0..8192] of byte;
begin
  inherited;
  loser := getuser(loser);
  if pendingresume then begin
    var t := 0;
    while not resumeaccepted do begin
      sleep(1000);
      inc(t);
      if t=15 then
        break;
      Status :='Waiting for resume';
      StepCount := 15;
      Step := t;

    end;
  end;
  if resumeaccepted then begin
    locallog('resume success!');
    status := 'Resume Success!';
  end;

  var cli := TLocalSocketClient.create;
  try
                    //xdcc
    Name := SimpleOB('YEBB')+': #'+trackingnumber.tostring+' '+extractfilename(localfile);
//    cli.BlockMode := bmBlocking;
    cli.HostName := ip;
    cli.EndPoint := port.tostring;
    cli.Connect;
    var fs : TLocalFileStream := nil;
    if resumeaccepted then begin
      fs := TLocalFileStream.create(localfile, fmOpenReadWrite+fmShareExclusive);
      fs.position := fs.size;
    end else
      fs := TLocalFileStream.create(localfile, fmCReate);

    try
      StepCount := size;
      while cli.Connected do begin
        if gettimesince(lastnotify) > 20000 then begin


          Status := ('receiving file '+extractfilename(localfile)+' @'+commaize(fs.size)+' ['+round(volatile_progress.percentcomplete*100).tostring+'%]');
          if assigned(irc.FOnXDCCProgress) then irc.FOnXDCCProgress(self);

          lastnotify := getticker;
        end;

        if cli.WaitForData(1000) then begin
          var iJust := cli.ReadData(@a[0], 8192);


          if iJust<=0 then
            exit;//disconnect/finish
          Stream_GuaranteeWrite(fs, @a[0], iJust);
          step := fs.size;
        end else begin
          //this seems to let us DISCONNECT on SUCCESS faster
          if (size > 0) and (fs.size = size) then
            cli.disconnect;
        end;



      end;
    finally
      if (fs.size <> size) and (size > 0) then begin
        ErrorMessage := 'Did not download entire file';
      end else begin
        ErrorMEssage := '';
      end;
      fs.free;
    end;

  finally
    cli.free;
  end;

end;

procedure TXDCCCommand.Init;
begin
  inherited;
  Icon :=  @CMD_ICON_XDCC;
end;

procedure TXDCCCommand.InitExpense;
begin
  inherited;
  CPuExpense := 0;
end;

{ TPack }

function TPack.Idiot: string;
begin
  result := loser;
  result := stringreplace(result, '\','', [rfReplaceAll,rfIgnoreCase]);
  result := stringreplace(result, ':','', [rfReplaceAll,rfIgnoreCase]);
  result := stringreplace(result, '?','', [rfReplaceAll,rfIgnoreCase]);
  result := stringreplace(result, '|',' ', [rfReplaceAll,rfIgnoreCase]);
end;

function TPack.TempFileName: string;
begin
  result := GetTempPath+idiot+'\'+filename;
  forcedirectories(extractfilepath(result));


end;

{ TChatConversation }

procedure TChatMultiUserClient.ChatCommand(s: string);
begin
  var h := ParseStringNotInH(s,' ','"');

  if h.o.count < 1 then exit;

  var cmd := h.o[0];

  h.o.delete(0);
  ChatCommand(cmd, h.o);




end;

procedure TChatConversation.ChatReceived(sFrom, sMessage: string);
begin
  if assigned(FonChatReceived) then begin
    var sl := ParseStringH(sMessage, IRCCONT);
    for var t:= 0 to sl.o.count-1 do begin
      FonChatReceived(self, sFrom, sl.o[t]);
    end;
  end;
end;

constructor TChatConversation.Create;
begin
  inherited;
  FLines := TStringList.create;
  FUsers := TStringList.create;
  CommandTrigger := '!';
end;

function TChatConversation.default_handle_Command(sOriginalLine,
  sWho, sCmd_lowercase: string; params: TStringlist): boolean;
begin
  result := false;
  if uppercase(scmd_lowercase) = SimpleOb('QSHWLRF') then begin
    result := default_handle_command_privmsg(sOriginalLine, sWho, sCmd_LowerCase, params);
  end;


end;

function TChatConversation.default_handle_command_privmsg(sOriginalLine,
  sWho, sCmd_lowercase: string; params: TStringlist): boolean;
begin
  var s := params[0];
  if zcopy(s,0,1) = ':' then
    s := zcopy(s, 1,length(s)-1);
  ChatReceived(sWho,s);
  result := true;
end;

procedure TChatConversation.Detach;
begin
  if detached then
    exit;

  FLines.free;
  FUsers.free;

  inherited;

end;

function TChatConversation.GetUsers: IHolder<TStringList>;
begin
//  var l := LockI;
  Lock;
  try
    result := THolder<TSTringlist>.create;
    result.o  := TSTringList.create;
    result.o.Text := FUsers.Text;
  finally
    Unlock;
  end;

end;

function TChatConversation.handle_Command(sOriginalLine, sWho, sCmd_lowercase: string;
  params: TStringlist): boolean;
begin
  TrimStringListDeleteEmpty(params);
  result := false;
  if assigned(fOnCommand) then
    result := fOnCommand(sWho,sOriginalLine, sCmd_lowercase, params);


  if not result then begin
    default_handle_command(soriginalLine, sWho, scmd_lowercase, params);
  end;


end;

function TChatConversation.handle_command_names(sOriginalLine, sWho,
  sCmd_lowercase: string; params: TStringlist): boolean;
begin
   result := false;
//  raise ECritical.create('unimplemented');
//TODO -cunimplemented: unimplemented block
end;

procedure TChatConversation.inviteUser(user: string);
begin
  irc.invite(user, self.channel);  
end;

procedure TChatConversation.RawLineReceived(sfrom, sMessage: string);
begin
  //this is a chat
  var sFromNick := '';
  var sFromEmail := '';
  SplitString(sFrom, '!', sFromNick, sFromEmail);
  if length(sMessage)>=2 then begin

    //is this a command?
    if sMessage[STRZ] = '@' then begin
      var h := ParseStringNotInH(sMessage, ' ', '"');
      if h.o.count < 2 then begin
        PrivMsg('no command specified, try @'+irc.nick+' help');
        exit;
      end;

      var who := h.o[0];
      var cmd := lowercase(h.o[1]);
      h.o.delete(0);
      h.o.delete(0);

      if 0=comparetext(who, '@'+self.irc.nick) then begin
        handle_Command(sMessage, who, cmd, h.o);
      end;
    end;

  //is this a command for the channel bot?
    if not IgnoreExcl then
    if sMessage[STRZ] = CommandTrigger then begin
      var h := ParseStringNotInH(sMessage, ' ', '"');

      var cmd := zcopy(lowercase(h.o[0]),1,99999);
      h.o.delete(0);
      handle_Command(sMessage, sFromNick, cmd, h.o);

    end;


    if assigned(OnLineReceived) then
      OnLineReceived(self, sFrom, sMessage);

    ChatReceived(sFrom, sMessage);
  end else begin
    if assigned(OnLineReceived) then
      OnLineReceived(self, sFrom, sMessage);
  end;

end;

function TChatConversation.LinesAvailable: string;
begin

//  raise ECritical.create('unimplemented');
//TODO -cunimplemented: unimplemented block
end;

function TChatConversation.ReadLn: string;
begin

//  raise ECritical.create('unimplemented');
//TODO -cunimplemented: unimplemented block
end;


procedure TChatConversation.UserJoined(sUser: string);
begin
//  var l := LockI;
  Lock;
  try
    var i := FUsers.INdexOf(sUser);
    if i < 0 then begin
      FUsers.Add(sUser);
      MMQ.QuickBroadcast('ChannelUsersUpdated');
      if assigned(FOnUserEntersRoom) then
        FOnUserEntersRoom(sUser);

    end;
  finally
    Unlock;
  end;

end;

procedure TChatConversation.UserLeft(sUser: string);
begin
//  var l := LockI;
  Lock;
  try
    var i := FUsers.IndexOf(sUser);
    if i >=0 then
      FUsers.delete(i);
    MMQ.QuickBroadcast('ChannelUsersUpdated');
  finally
    Unlock;
  end;

end;

procedure TChatConversation.Part;
begin
  irc.part(self.channel);
end;

procedure TChatConversation.PM(s: string);
begin
  Lock;
  try
  if FPmHold<>'' then
    s := FPMHold+s;
  FPMHold := '';
  PrivMsg(s);
  finally
    unlock;
  end;
end;

procedure TChatConversation.PMCon(sExpression: string);
begin
  PM(ESCIRC_CON+sExpression);
end;

procedure TChatConversation.PMConLn(sExpression: string);
begin
  PMCon(sExpression+'`n`');
end;

procedure TChatConversation.PMHold(s: string);
begin
  Lock;
  try
  if CountChar(s, ESCIRC) and 1 = 1 then
    FPMHold := FPmHold+s+ESCIRC
  else
    FPmHold := FPmHold+s;
  finally
    Unlock;
  end;
end;

procedure TChatConversation.PMMultiLine(s: string);
begin
  var slh := stringToStringListH(s);
  for var t:= 0 to slh.o.Count-1 do begin
    PM(slh.o[t]);
  end;
end;

procedure TChatConversation.PrivMsg(s: string);
begin
  Lock;
  try
    irc.PrivMsg(channel, s);
    self.ChatReceived(irc.nick, s);
  finally
    Unlock;
  end;

end;

{ TLocalSocketclient }

function TLocalSocketclient.ReadSCrambledLn(out sLine: string;
  iTimeout: nativeint): boolean;
begin
  result := ReadLn(sLine, iTimeout);
  if result then begin
    if Scrambled then begin
      sLine := unscrambleString(sLine);
    end;

  end;
end;

function TLocalSocketclient.ScrambleString(s: string): string;
begin
  result := s;
  if not scrambled then
    exit;
  for var t:= low(s) to high(s) do begin
    case s[t] of #13, #10,#$58,#$5F: begin
      end else begin
      result[t] := char(ord(s[t]) xor $55);
      end;
    end;

  end;

end;

function TLocalSocketclient.SendScrambledLine(sLine: string): string;
begin
  if SCrambled then
    sLine := ScrambleString(sLine);
  sendln(sline);
end;

function TLocalSocketclient.UnScrambleString(s: string): string;
begin
  result := ScrambleString(s);
end;

end.
