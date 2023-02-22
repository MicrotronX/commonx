﻿unit exe;
// (WINDOWS ONLY)
// This unit contains EXE spawning and management functions.
// - Launch EXES
// - Wait for EXEs
// - check for running tasks
// - kill tasks

//NOTES ABOUt CONSOLE REDIRECTION
//I thought I was insane, but some apps write to stdout some write to
//stderr so this was recently modified to capture both.
//HOWEVER ffmpeg doesn't seem to like being run inside a batch file and
//maybe it detects the scenario and opens its own console window...
//that's the only way I can explain it.
//tested with BATCH files... works fine with echos to stdout and stderr.


{$DEFINE ALLOW_CONSOLE_REDIRECT}
{x$DEFINE NO_INHERIT_HANDLES}
{$DEFINE SEGREGATE_CONSOLE_REDIRECT}
{x$DEFINE USE_SW_SHOWNA}  //Disabled in 2020, this option, when enabled was causing CMD windows to pop-up during console captures... making the console captures FAIL

//TODO 1: Figure out why .BATs run with command but not with direct call to RunProgram()

interface


uses

{$IFDEF MSWINDOWS}
  debug, sysutils, typex, numbers, winapi.TlHelp32, WinSvc,
  winapi.windows, betterobject,
  managedthread, classes, rtti_helpers, ShellAPI, dirfile,
  commandprocessor, backgroundthreads, commandicons, tickcount,
{$ENDIF}
  dir, orderlyinit;

{$IFDEF MSWINDOWS}
const
  NO_RETURN_HANDLE = DWORD(-2);
  DEFAULT_PRIORITY_CLASS = NORMAL_PRIORITY_CLASS;

type
  TQueryFullProcessImageNameW = function(AProcess: THANDLE; AFlags: DWORD;
    AFileName: PWideChar; var ASize: DWORD): BOOL; stdcall;
  TGetModuleFileNameExW = function(AProcess: THANDLE; AModule: HMODULE;
    AFilename: PWideChar; ASize: DWORD): DWORD; stdcall;

  TProcessInfo = record
    pid: ni;
    ExeName: string;
    running: boolean;
    runningCount: ni;

    fileDate: TDateTime;
    function handlecount: ni;
    function FullPath: string;
    procedure Init;
  end;
  TRunningTask = record
  private
   public
    exeName: string;
    FullExeName: string;
    Parameters: string;
    processid: int64;
    function fileDate: TDateTime;
    procedure Init;
    function HandleCount: ni;
    class operator notequal(a,b: TRunningTask): boolean;
  end;
  TConsoleHandles = record
    stdOUTread, stdOUTWrite: THandle;
    stdINread, stdINWrite: THandle;
    stdERRread, stdERRWrite: THandle;
    procedure Init;
  end;
  TBetterProcessInformation = record
    pi: TProcessInformation;
    DynamicFile: string;
    procedure Init;
  end;
type
  EConsoleRedirect = class(Exception);
  TConsoleCaptureStatus = (ccStart, ccProgress, ccEnd);

  TConsoleCaptureHook = procedure(ccStatus: TConsoleCaptureStatus;
    sBufferData: string) of object;

function RunProgramAndWait(const sProg, sParams, sWorkDir: string;
  bHide: boolean = false; batchwrap: boolean = false; bElevate: boolean = false; priorityclass: integer = DEFAULT_PRIORITY_CLASS): boolean;
function StartCMDfromCMD(sProg, sParams, sWkDir: string; bHide: boolean = false;
  batchwrap: boolean = false; bElevate: boolean = false; priorityclass: integer = DEFAULT_PRIORITY_CLASS): TBetterProcessInformation;
function RunProgram(sProg, sParams, sWkDir: string; bHide: boolean = false;
  batchwrap: boolean = false; bElevate: boolean = false): TBetterProcessInformation; overload;
procedure CleanDynamicFolder;
function RunProgram(var hands: TConsoleHandles;
  sProg, sParams, sWkDir: string; bHide: boolean = false;
  batchwrap: boolean = false; bElevate: boolean = false; priorityclass: integer = DEFAULT_PRIORITY_CLASS): TBetterProcessInformation; overload;

procedure WaitForEXE(var hProcessInfo: TBetterProcessInformation; bCloseHandle: boolean = true);
function TryWaitForEXE(var hProcessInfo: TBetterProcessInformation): boolean;
procedure ForgetExe(var hProcessInformation: TBetterProcessInformation);
procedure RunAndCapture(DosApp: string; wkdir: string; cc: TConsoleCaptureHook; Timeout: ticker; priorityclass: integer = DEFAULT_PRIORITY_CLASS);
function RunExeAndCapture(app: string; params: string = ''; wkdir: string = ''): string;
function ServiceGetStatus(sMachine, sService: PChar): DWORD;
function GetFullPathFromPID(PID: DWORD): string;
function GetFileNameByProcessID(AProcessID: DWORD): UnicodeString;
function GetProcessList(exeNameORFullPathNameIfYouWantToCheckSpecificPath: string; iForceCount: ni = 0): Tarray<TProcessInfo>;
function GetHandleCountFromPID(pid: int64): ni;

type
  TWAitForExeThread = class(TProcessorThread)
  private
    FExehandle: TBetterProcessInformation;
  public
    procedure Init;override;
    procedure DoExecute; override;
    property ExeHandle: TBetterProcessInformation read FExehandle write FExehandle;
  end;

  TWaitForExeCommand = class(TCommand)
  private
    FExehandle: THandle;
  public
    hProcessInfo: TBetterProcessInformation;
    hCreatingThread: THandle;
    procedure Init;override;
    procedure InitExpense; override;
    procedure DoExecute; override;
    property ExeHandle: THandle read FExehandle write FExehandle;
  end;

  TServiceInfo = record
    DisplayName: string;
    Name: string;
    State: string;
    procedure Init;
    function filled: boolean;
  end;

  Tcmd_RunExe = class(TCommand)
  private
    FExehandle: THandle;
    FProg: string;
    FParams: string;
    FWorkingdir: string;
    FHide: boolean;
    FBatchWrap: boolean;
    FPipeDebug: boolean;
    FDebugFile: string;
    FElevate: boolean;
    FConsoleRedirect: boolean;
    FHung: boolean;
    FTimeOut: cardinal;
    FCaptureConsoleOutput: boolean;
    FConsoleOutput: string;
    FConsoleTemp: string;
    FConsoleOutputPointer: Pbyte;
    FIsWindowed: boolean;
    FConsoleDrain: string;
    FGPUParams: string;
    FPriorityClass: integer;
    function GetConsoleOutput: string;
    procedure SetIswindowed(const Value: boolean);
    procedure SetProg(const Value: string);
  protected
    hands: TConsoleHandles;
    LAstACtiveTime: cardinal;
    procedure BuildCommandLine;virtual;
    procedure CC(ccStatus: TConsoleCaptureStatus; sData: string);virtual;
    procedure UseConsoleRedirExecutionPath;
  public

    hProcessInfo: TBetterProcessInformation;
    hCreatingThread: THandle;
    procedure Init;override;
    procedure InitExpense; override;
    procedure Preprocess;override;
    procedure DoExecute; override;
    function DrainConsole: string;
    property ExeHandle: THandle read FExehandle write FExehandle;
    property Prog: string read FProg write SetProg;
    property Params: string read FParams write FParams;
    property GPUParams: string read FGPUParams write FGPUParams;
    property WorkingDir: string read FWorkingdir write FWorkingdir;
    property Hide: boolean read FHide write FHide;
    property batchwrap: boolean read FBatchWrap write FBatchWrap;
    property PipeDebug: boolean read FPipeDebug write FPipeDebug;
    procedure ConsoleStatus(cc: TConsoleCaptureStatus; s: string);
    property Elevate: boolean read FElevate write FElevate;
    property ConsoleRedirect: boolean read FConsoleRedirect write fConsoleRedirect;
    property Hung: boolean read FHung write FHung;
    procedure CheckIfHungAndTerminate;
    property Timeout: cardinal read FTimeOut write FTimeout;
    property CaptureConsoleoutput: boolean read FConsoleRedirect write FConsoleRedirect;
    property ConsoleOutput: string read GetConsoleOutput;
    property IsWindowed: boolean read FIsWindowed write SetIswindowed;
    property PriorityClass: integer read FPriorityClass write FPriorityClass;
    procedure Terminate;


  end;

function GetRunningServices(): IHolder<TStringList>;
function GetAllServices: TArray<TServiceInfo>;
function GetServicesNamed(sName: string): TArray<TServiceInfo>;
function IsServiceInstalled(sName: string): boolean;

function IsServiceRunning(sDisplayName: string): boolean;


function IsTaskRunning_old(sImageName: string): boolean;
function IsTaskRunning(sImageName: string): boolean;
function IsTaskRunningInPath(sImageName: string; sPath: string): boolean;


function NumberOfTasksRunning(sImageName: string): nativeint;
function NumberOfTasksRunningInPath(sFullEXEName: string): nativeint;
function NumberOfTasksRunningFlex(sFullEXEName: string): nativeint;
function KillTasksByNameWithTimeoutForce(sImageName: string; bKillAll: boolean = true; bKillchildTasks: boolean = false; iTimeout: nativeint = 60000): boolean;
function KillTasksInFolderByNameWithTimeoutForce(sFullPathToEXE: string; bKillAll: boolean = true; bKillchildTasks: boolean = false; iTimeout: nativeint = 60000): boolean;
function KillTaskByName(sImageName: string; bKillAll: boolean = true; bKillchildTasks: boolean = false; bForce: boolean = true): boolean;
function TryKillTaskByName(sImageName: string; bKillAll: boolean = true; bKillchildTasks: boolean = false; bForce: boolean = true): boolean;
function TryKillTaskInFolderByName(sImageNameWithPathOptional: string; bKillAll: boolean = true; bKillchildTasks: boolean = false; bForce: boolean = true): boolean;
procedure KillTaskByID(pid: ni; bForce: boolean = true);
function processExists(exeFileName: string): Boolean;
function GetProcessInfo(exeFileName: string): TProcessInfo;
function ServiceCommand(sCmd: string; sServiceName: string): string;
function GetNetCommandPath: string;
function StartService(sServiceName: string): boolean;
function StopService(sServiceName: string): boolean;
function GetTaskListEx(): IHolder<TStringList>;
function GetTaskListExArray(): TArray<TRunningTask>;overload;
function GetTaskListExArray(exefilter: string; paramfilter: string = ''): TArray<TRunningTask>;overload;
function GetTaskListExArrayInFolder(exefilter, folder: string; paramfilter: string = ''): TArray<TRunningTask>;overload;


var
  ExeCommands: TCommandProcessor =nil;
  PsapiLib: HMODULE = 0;
  GetModuleFileNameExW: TGetModuleFileNameExW;


procedure CreateElevateScripts(sDir: string);

{$ENDIF}

implementation

uses
  stringx, systemx;

{$IFDEF MSWINDOWS}



function GetHandleCountFromPID(pid: int64): ni;
var
  pi: TProcessInfo;
begin
  try
    pi.pid := pid;
    result := pi.handlecount;
  except
    exit(0);
  end;
end;

function GetTaskListExArraySub(): TArray<TRunningTask>;
var
  current: TRunningTask;
begin
  Debug.Log('GetTaskListExArraySub()');
  var sl := GetTasklistEx();
  setlength(result, 0);
  for var t := 0 to sl.o.count-1 do begin
    var sLine := sl.o[t];
    var l,r: string;

    if SplitString(sLine, '=', l,r) then begin
      if lowercase(l) = 'commandline' then begin
        SplitStringNoCaseEx(r, ' ', l, r, '"', '"');
        current.Parameters := r;
      end;
      if lowercase(l) = 'executablepath' then begin
        current.FullExeName:= r;
      end;
      if lowercase(l) = 'name' then begin
        current.exename := r;
      end;
      if lowercase(l) = 'processid' then begin
        current.processid := strtoint64(r);
        setlength(result, length(result)+1);
        result[high(result)] := current;
        current.init;
      end;
    end;
  end;
end;

function GetTaskListExArray(): TArray<TRunningTask>;
{$IFDEF VERIFY}
var
  t1, t2,t3: TArray<TRunningTask>;
  stable: boolean;
{$ENDIF}
begin
{$IFDEF VERIFY}
  repeat
    stable := false;
    t1 := GetTaskListExArraySub();
    t2 := GetTaskListExArraySub();
    t3 := GetTaskListExArraySub();

    if high(t1) <> high(t2) then
      continue;
    if high(t1) <> high(t3) then
      continue;

    stable := true;
    for var t := 0 to high(t1) do begin
      if (t1[t] <> t2[t]) or (t1[t]<>t3[t]) then begin
        stable := false;
      end;
    end;

  until stable;
{$ELSE}
  result := GetTaskListExArraySub();
{$ENDIF}



end;

function GetTaskListExArray(exefilter: string; paramfilter: string = ''): TArray<TRunningTask>;
var
  tl: TArray<TRunningTask>;
begin
  tl := GetTaskListExArray();
//  result := tl;
//  exit;
  Debug.Log('Filtering task list containing '+length(tl).tostring+' entries.');
  var count := 0;
  for var t := 0 to high(tl) do begin
//    DEbug.Log('unfiltered : '+tl[t].exeName);
    if (exefilter = '')  or (lowercase(tl[t].exeName) = lowercase(exefilter)) then begin
      if (paramfilter = '')
      or (zpos(lowercase(paramfilter),lowercase(tl[t].Parameters)) >=0)
      then begin
        inc(count);
      end;
    end;
  end;

  Debug.Log('Found '+count.tostring+' instances of '+exefilter);
  setlength(result, count);
  if count = 0 then
    exit;

  var idx: ni := 0;
  Debug.Log('Rescanning task list');
  for var t := 0 to high(tl) do begin
    if (exefilter = '') or (lowercase(tl[t].exeName) = lowercase(exefilter)) then begin
      if (paramfilter = '')
      or (zpos(lowercase(paramfilter),lowercase(tl[t].Parameters)) >=0)
      then begin
        Debug.Log('Adding to result idx '+idx.tostring);
        result[idx]:= tl[t];
        inc(idx);
      end;
    end;
  end;
  setlength(result, count);//truncate
  Debug.Log('Finished with GetTaskListExArray()');

end;

function GetTaskListExArrayInFolder(exefilter, folder: string; paramfilter: string = ''): TArray<TRunningTask>;overload;
var
  ar: TArray<TRunningTask>;
begin
  if folder = '' then
    exit(GetTaskListExArray(exefilter, paramfilter));

  ar := GEtTaskListExArray(exeFilter, paramfilter);
  setlength(ar, length(ar));
  setlength(result, length(ar));
  var idx := 0;
  for var t:= 0 to high(ar) do begin
    if comparetext(ar[t].FullExeName, slash(folder)+exefilter)=0 then begin
      result[idx] := ar[t];
      inc(idx);
    end;
  end;
  setlength(result, idx);


end;




function GetTaskListEx(): IHolder<TStringList>;
begin
  var sTasks := exe.RunExeAndCapture(getsystemdir+'wbem\wmic.exe', 'process get name,processid,commandline,executablePath /format:value');
    result := stringToStringListH(sTasks);


  for var t := result.o.Count-1 downto 0 do begin
    if trim(result.o[t]) = '' then
      result.o.Delete(t);
  end;

  result.o.delete(0);


end;



function StartService(sServiceName: string): boolean;
begin
  var s := ServiceCommand('start', sServiceName);

  result := zpos('failed', s) < 0;

end;

function StopService(sServiceName: string): boolean;
begin
  var s := ServiceCommand('stop', sServiceName);

  result := zpos('failed', s) < 0;
end;

function GetNetCommandPath: string;
begin
  result := GetSystemDir+'net.exe';
end;

function ServiceCommand(sCmd: string; sServiceName: string): string;
begin
  result := exe.RunExeAndCapture(GetNetCommandPath, sCMD+' '+Quote(sServiceName));
end;

function IsServiceRunning(sDisplayName: string): boolean;
begin
  var services := GetRunningServices();

  for var t := 0 to services.o.count-1 do begin
    var sline := services.o[t];

    if comparetext(sLine, sDisplayName)=0 then
      exit(true);

  end;

  result := false;


end;

function GetRunningServices(): IHolder<TStringList>;
begin

//  var sTasks := exe.RunExeAndCapture(getsystemdir+'tasklist.exe');
//  result := stringtostringlisth(sTasks);
  var c := Tcmd_RunExe.create;
  try
    c.Prog := getsystemdir+'net.exe';
    c.Params := 'start';
    c.batchwrap := true;
//    c.CaptureConsoleoutput := true;
    c.start;
    c.Hide := true;
    c.WaitFor;
    var services := c.ConsoleOutput;

    var temp := stringToStringListH(services);

    result := stringToStringListH('');

    for var t := 1 to temp.o.Count-1 do begin
      var sLine := temp.o[t];
      sLine := trim(sLine);

      if (sLine <> '') and (0<>Comparetext('The command completed successfully.', sLine)) then
        result.o.add(sLine);


    end;
  finally
    c.Free;
  end;


end;

function NumberOfTasksRunning(sImageName: string): nativeint;
var
  sTasks: string;
  h: IHolder<TStringlist>;
  t: ni;
  sLine: string;
  sExtra, sProg: string;
begin
  result := 0;
  sImageName := lowercase(sImageName);
  sTasks := exe.RunExeAndCapture(getsystemdir+'tasklist.exe');
//  SaveStringAsFile(dllpath+'tasks.txt', stasks);
  h := stringToStringListH(lowercase(sTasks));
  for t:= 0 to h.o.count-1 do begin
    sLine := h.o[t];
    Debug.Log(sLine);
//    if zcopy(sLine, 0,4) = 'nice' then
//      Debug.Log('here');
    if SplitString(sLine, ' ', sProg, sExtra) then begin
      if comparetext(sProg, sImageName)=0 then
        inc(result);
//      else
//        Debug.log('NOT! '+sline);
    end;
    if SplitString(sLine, #9, sProg, sExtra) then begin
      if comparetext(sProg, sImageName)=0 then
        inc(result);
//      else
//        Debug.log('NOT #9 '+sline);
    end;
  end;

end;

function NumberOfTasksRunningInPath(sFullEXEName: string): nativeint;
var
  ar: tArray<TRunningTask>;
begin
  var image := extractfilename(sFullEXEName);
  var path := extractfilepath(sFullEXEName);
  if path = '' then
    ar := GetTaskListExArray(image)
  else
    ar := GetTaskListExArrayInFolder(image, path);

  result := length(ar);

end;

function NumberOfTasksRunningFlex(sFullEXEName: string): nativeint;
begin
  result := NumberOfTasksRunningInPath(sFullEXEName);
end;





function IsTaskRunningLL(sImageName: string): boolean;
var
  sTasks: string;
  h: IHolder<TStringlist>;
  t: ni;
  sLine: string;
begin
  result := false;
  sImageName := lowercase(sImageName);
  sTasks := exe.RunExeAndCapture(getsystemdir+'tasklist.exe');
//  SaveStringAsFile('d:\tasks.txt', stasks);
  h := stringToStringListH(lowercase(sTasks));
  for t:= 0 to h.o.count-1 do begin
    sLine := h.o[t];
//    Debug.Log(sLine);
//    if zcopy(sLine, 0,4) = 'nice' then
//      Debug.Log('here');
    if StartsWithNoCase(sLine, sImageName) then
      exit(true);
  end;

end;


function IsTaskRunningInPath(sImageName: string; sPath: string): boolean;
var
  ar: TArray<TRunningTask>;
begin
  ar := GetTaskListExArray(sImageName);
  result := false;
  for var t := 0 to high(ar) do begin
    if comparetext(ar[t].FullExeName, slash(sPath)+sImageName)=0 then
      exit(true);
  end;
end;

function IsTaskRunning(sImageName: string): boolean;
var
  ar: TArray<TRunningTask>;
begin
  ar := GetTaskListExArray(sImageName);
  result := length(ar) > 0;
end;
function IsTaskRunning_old(sImageName: string): boolean;
var
  t: ni;
begin
  result := false;
  for t:= 0 to 9 do begin
    if IsTaskRunningLL(sImageName) then
      exit(true);
  end;
end;

function KillTaskByName(sImageName: string; bKillAll: boolean = true; bKillchildTasks: boolean = false; bForce: boolean = true): boolean;
var
  sTasks: string;
  tflag: string;
  fflag: string;
begin
  tflag := '';
  fflag := '';
  if bKillchildTasks then
    tflag := ' /T';
  if bForce then
    fflag := ' /F';
  result := false;
  exe.RunProgramAndWait(getsystemdir+'taskkill.exe', '/IM "'+sImageName+'"'+tflag+fflag, DLLPath, true, false);
  while IsTaskRunning(sImageName) do begin
    Debug.Log('Task '+sImageName+' is still running, retry terminate.');
    exe.RunProgramAndWait(getsystemdir+'taskkill.exe', '/IM "'+sImageName+'"'+tflag+fflag, DLLPath, true, false);
    sleep(2000);
    result := true;
    if not bKillall then
      exit;
  end;
end;

function KillTasksByNameWithTimeoutForce(sImageName: string; bKillAll: boolean = true; bKillchildTasks: boolean = false; iTimeout: nativeint = 60000): boolean;
var
  sTasks: string;
  tflag: string;
  fflag: string;
begin
  var tmStart := GetTicker;
  var bForce := false;
  tflag := '';
  fflag := '';
  if bKillchildTasks then
    tflag := ' /T';
  if bForce then
    fflag := ' /F';
  result := false;
  exe.RunProgramAndWait(getsystemdir+'taskkill.exe', '/IM "'+sImageName+'"'+tflag+fflag, DLLPath, true, false);
  while IsTaskRunning(sImageName) do begin
    bForce := getTimeSince(tmStart) > iTimeout;
    if bForce then
      fflag := ' /F';
    Debug.Log('Task '+sImageName+' is still running, retry terminate.');
    exe.RunProgramAndWait(getsystemdir+'taskkill.exe', '/IM "'+sImageName+'"'+tflag+fflag, DLLPath, true, false);
    sleep(2000);
    result := true;
    if not bKillall then
      exit;
  end;
end;


function KillTasksInFolderByNameWithTimeoutForce(sFullPathToExe: string; bKillAll: boolean = true; bKillchildTasks: boolean = false; iTimeout: nativeint = 60000): boolean;
var
  sTasks: string;
  tflag: string;
  fflag: string;
  ar: TArray<TRunningTask>;
begin
  var sImageName := extractfilename(sFullPathToExe);
  var sPath := extractfilepath(sFullPathToExe);
  var tmStart := GetTicker;
  var bForce := false;
  tflag := '';
  fflag := '';
  if bKillchildTasks then
    tflag := ' /T';
  if bForce then
    fflag := ' /F';
  result := false;
  ar := GetTaskListExArrayInFolder(sImageName, sPath);
  FOR VAR T:= 0 to high(ar) do begin
    exe.RunProgramAndWait(getsystemdir+'taskkill.exe', '/PID '+ar[t].processid.tostring+' '+tflag+fflag, DLLPath, true, false);
  end;

  while IsTaskRunninginPath(sImageName, sPAth) do begin
    bForce := getTimeSince(tmStart) > iTimeout;
    if bForce then
      fflag := ' /F';
    Debug.Log('Task '+sImageName+' is still running, retry terminate.');


    ar := GetTaskListExArrayInFolder(sImageName, sPath);
    FOR VAR T:= 0 to high(ar) do begin
      exe.RunProgramAndWait(getsystemdir+'taskkill.exe', '/PID '+ar[t].processid.tostring+' '+tflag+fflag, DLLPath, true, false);
    end;

    sleep(2000);
    result := true;
    if not bKillall then
      exit;
  end;
end;

function TryKillTaskByName(sImageName: string; bKillAll: boolean = true; bKillchildTasks: boolean = false; bForce: boolean = true): boolean;
var
  sTasks: string;
  tflag: string;
  fflag: string;
begin
  tflag := '';
  fflag := '';
  if bKillchildTasks then
    tflag := ' /T';
  if bForce then
    fflag := ' /F';
  result := false;
  exe.RunProgramAndWait(getsystemdir+'taskkill.exe', '/IM "'+sImageName+'"'+tflag+fflag, DLLPath, true, false);
  if IsTaskRunning(sImageName) then begin
    Debug.Log('Task '+sImageName+' is still running, retry terminate.');
    exe.RunProgramAndWait(getsystemdir+'taskkill.exe', '/IM "'+sImageName+'"'+tflag+fflag, DLLPath, true, false);
  end;
  result := not IsTaskRunning(sImageName);


end;


function TryKillTaskInFolderByName(sImageNameWithPathOptional: string; bKillAll: boolean = true; bKillchildTasks: boolean = false; bForce: boolean = true): boolean;
var
  sTasks: string;
  tflag: string;
  fflag: string;
  ar: TArray<TRunningTask>;
begin
  var sPath := extractfilepath(sImagenamewithpathoptional);
  var sImage := extractfilename(sImageNameWithPathOptional);
  tflag := '';
  fflag := '';
  if bKillchildTasks then
    tflag := ' /T';
  if bForce then
    fflag := ' /F';
  result := false;

  if sPath = '' then
    ar := GetTaskListExArray(sImage)
  else
    ar := GetTaskListExArrayInFolder(sImage, sPath);

  FOR VAR T:= 0 to high(ar) do begin
    exe.RunProgramAndWait(getsystemdir+'taskkill.exe', '/PID '+ar[t].processid.tostring+' '+tflag+fflag, DLLPath, true, false);
  end;


  if sPath = '' then
    result := not IsTaskRunning(sImage)
  else
    result := not IsTaskRunningInPath(sImage, sPath);

end;

procedure KillTaskByID(pid: ni; bForce: boolean = true);
begin
  var sForce := '';
  if bForce then
    sForce := ' /F';

  exe.RunProgramAndWait(getsystemdir+'taskkill.exe', '/PID '+pid.tostring+' /T'+sForce, DLLPath, true, false);
end;

procedure CreateElevateScripts(sDir: string);
var
  sl: TStringLIst;
begin
  sl := TStringLIst.create;
  try

    sl.add('@echo off');
    sl.add('');
    sl.add(
      ':: Pass raw command line agruments and first argument to Elevate.vbs');
    sl.add(':: through environment variables.');
    sl.add('set ELEVATE_CMDLINE=%*');
    sl.add('set ELEVATE_APP=%1');
    sl.add('');
    sl.add('start wscript //nologo "%~dpn0.vbs" %*');
    sl.SaveToFile(slash(sDir) + 'elevate.cmd');

    sl.clear;

    sl.add('Set objShell = CreateObject("Shell.Application")');
    sl.add('Set objWshShell = WScript.CreateObject("WScript.Shell")');
    sl.add('Set objWshProcessEnv = objWshShell.Environment("PROCESS")');
    sl.add('');
    sl.add(
      ''' Get raw command line agruments and first argument from Elevate.cmd passed');
    sl.add(''' in through environment variables.');
    sl.add('strCommandLine = objWshProcessEnv("ELEVATE_CMDLINE")');
    sl.add('strApplication = objWshProcessEnv("ELEVATE_APP")');
    sl.add(
      'strArguments = Right(strCommandLine, (Len(strCommandLine) - Len(strApplication)))');
    sl.add('');
    sl.add('If (WScript.Arguments.Count >= 1) Then');
    sl.add('    strFlag = WScript.Arguments(0)');
    sl.add(
      '    If (strFlag = "") OR (strFlag="help") OR (strFlag="/h") OR (strFlag="\h") OR (strFlag="-h") _');
    sl.add(
      '        OR (strFlag = "\?") OR (strFlag = "/?") OR (strFlag = "-?") OR (strFlag="h") _');
    sl.add('        OR (strFlag = "?") Then');
    sl.add('        DisplayUsage');
    sl.add('        WScript.Quit');
    sl.add('    Else');
    sl.add(
      '        objShell.ShellExecute strApplication, strArguments, "", "runas"'
      );
    sl.add('    End If');
    sl.add('Else');
    sl.add('    DisplayUsage');
    sl.add('    WScript.Quit');
    sl.add('End If');
    sl.add('');
    sl.add('');
    sl.add('Sub DisplayUsage');
    sl.add('');
    sl.add(
      '    WScript.Echo "Elevate - Elevation Command Line Tool for Windows Vista" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add('                 "Purpose:" & vbCrLf & _');
    sl.add('                 "--------" & vbCrLf & _');
    sl.add(
      '                 "To launch applications that prompt for elevation (i.e. Run as Administrator)" & vbCrLf & _');
    sl.add(
      '                 "from the command line, a script, or the Run box." & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add('                 "Usage:   " & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add
      ('                 "    elevate application <arguments>" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add('                 "Sample usage:" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add(
      '                 "    elevate notepad ""C:\Windows\win.ini""" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add(
      '                 "    elevate cmd /k cd ""C:\Program Files""" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add(
      '                 "    elevate powershell -NoExit -Command Set-Location ''C:\Windows''" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add(
      '                 "Usage with scripts: When using the elevate command with scripts such as" & vbCrLf & _');
    sl.add(
      '                 "Windows Script Host or Windows PowerShell scripts, you should specify" & vbCrLf & _');
    sl.add(
      '                 "the script host executable (i.e., wscript, cscript, powershell) as the " & vbCrLf & _');
    sl.add('                 "application." & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add('                 "Sample usage with scripts:" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add(
      '                 "    elevate wscript ""C:\windows\system32\slmgr.vbs"" â€“dli" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add(
      '                 "    elevate powershell -NoExit -Command & ''C:\Temp\Test.ps1''" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add(
      '                 "The elevate command consists of the following files:" & vbCrLf & _');
    sl.add('                 "" & vbCrLf & _');
    sl.add('                 "    elevate.cmd" & vbCrLf & _');
    sl.add('                 "    elevate.vbs" & vbCrLf');
    sl.add('');
    sl.add('End Sub');

    if not fileexists(slash(sDir) + 'elevate.vbs') then
      sl.SaveToFile(slash(sDir) + 'elevate.vbs');

  finally
    sl.free;
  end;
end;

// ------------------------------------------------------------------------------
function RunProgramAndWait(const sProg, sParams, sWorkDir: string;
  bHide: boolean = false; batchwrap: boolean = false; bElevate: boolean = false; priorityclass: integer = DEFAULT_PRIORITY_CLASS): boolean;
// Runs an Executable program, and waits for the program to complete.
var
  hTemp: TBetterProcessInformation;
begin
  result := false;
  hTemp := RunProgram(sProg, sParams, sWorkDir, bHide, batchwrap, bElevate);
  if hTemp.pi.hProcess <= 0 then begin
    raise Exception.create('Create process failed, result = ' + inttostr(hTemp.pi.hProcess)+' error='+inttostr(getlasterror)
      );
  end;
  if hTemp.pi.hProcess <> 0 then begin
    result := true;
    WaitForEXE(hTemp);
  end;
end;

// ------------------------------------------------------------------------------
function StartCMDfromCMD(sProg, sParams, sWkDir: string; bHide: boolean = false;
  batchwrap: boolean = false; bElevate: boolean = false; priorityclass: integer = DEFAULT_PRIORITY_CLASS): TBetterProcessInformation;
begin
  var progpath := extractfilePath(sProg);
  if progpath = '' then
    progpath := dllpath
  else begin
    if sWkDir <> progpath then begin
      Debug.Log('WARNING! WorkDir will be substituted with EXE path, a limitation of StartCMDfromCMD() due to the use of the windows "start" command');
      Debug.Log('Using '+progpath+' instead of '+sWkDir);
    end;
    sProg := extractfilename(sProg);
  end;



                              //vv don't quote this apparently
  result := RunProgram('start', sProg+' '+sParams, progpath, bHide, true, bElevate);
  CleanDynamicFolder;

end;

function RunProgram(sProg, sParams, sWkDir: string; bHide: boolean = false;
  batchwrap: boolean = false; bElevate: boolean = false): TBetterProcessInformation;
var
  hands: TConsoleHandles;
begin
  hands.Init;
  result := RunProgram(hands, sProg, sParams, sWkDir, bHide,
    batchwrap, bElevate);



end;

function RunProgram(
  var hands: TConsoleHandles;
  sProg, sParams, sWkDir: string; bHide: boolean = false;
  batchwrap: boolean = false; bElevate: boolean = false; priorityclass: integer = DEFAULT_PRIORITY_CLASS): TBetterProcessInformation;
// p: sProg: Program Name, include full path
// p: sParams: commandline parameters for the program... basically just concatinates.
// p: sWkDir: change to this directory before executing
// Runs an Executable program, returns a handle to the Executable.
var
  rStartup: _STARTUPINFOW;
  rProcess: TBetterProcessInformation;
  Security: TSecurityAttributes;
  sCommandLine: string;
// sWorkingDir: ansistring;
  sBat: string;
  sLeft, sRight: string;
  sDynamicFile: string;
  cl, cl2, d: PChar;
  bConRedir: boolean;
  sStartup, sSec: string;
begin
  if bElevate then
    BatchWrap := true;

  Debug.Log(nil,sProg + ' ' + sParams);

//  if batchwrap then
//    bHide := true;
  result.Init;
  sBat := '';
  if (lowercase(sProg) <> 'start') then begin

  end;
  FillMem(Pbyte(@rStartup), Sizeof(rStartup), 0);

  FillMem(Pbyte(@Security), Sizeof(TSecurityAttributes), 0);


  bConRedir := (hands.stdOUTREAD <> NO_RETURN_HANDLE)
           and (hands.stdOUTWrite <> NO_RETURN_HANDLE);
  if bConRedir then
    begin
    with Security do begin
      security.nlength := Sizeof(TSecurityAttributes);
      binherithandle := true;
      lpsecuritydescriptor := nil;
    end;

    hands.stdOUTREad := 0;
    hands.stdOUTWrite := 0;
    if not CreatePipe(hands.stdOUTRead, hands.stdOUTWrite, @Security, 0) then
      raise Exception.create('Unable to create pipe');
    if not CreatePipe(hands.stdINRead, hands.stdINWrite, @Security, 0) then
      raise Exception.create('Unable to create pipe');
    if not CreatePipe(hands.stdERRRead, hands.stdERRWrite, @Security, 0) then
      raise Exception.create('Unable to create pipe');



{$IFDEF NO_INHERIT_HANDLES}
    SetHandleInformation(hands.fromexe, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(hands.toexe, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(hands.fromexe, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(hands.toexe, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(hands.fromexe, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(hands.toexe, HANDLE_FLAG_INHERIT, 0);
{$ENDIF}



  end
  else begin
    hands.init;
  end;

  if lowercase(sprog)='start' then begin
    sCommandLine := 'start '+sParams;
  end else begin
    if sParams = '' then
      sCommandLine := Quote(sProg)
    else begin
      sCommandLine := Quote(sProg) + ' ' + sParams;
    end;
  end;

  if batchwrap then begin
    if (SplitString(sWkDir, ':', sBat, sRight)) then begin
      sBat := sBat + ':'#13#10;
      sBat := sBat + 'cd \'#13#10;
      sBat := sBat + 'cd "' + sWkDir + '"' + #13#10;
    end;

// if GetWinVersion in [wvWinVista] then begin
    if bElevate then
      sCommandLine := GetTempPath+'elevate.cmd ' + Quote(sCommandLine);


    sBat := sBat + sCommandLine +#13#10;
    Debug.Log('created batch file:'#13#10+sBat);
    //sBat := sBat + 'pause'#13#10;
    // sBat := sBat+'pause'#13#10;

    sDynamicFile := slash(systemx.GetTempPath) + 'dynamic_' + inttostr(GetCurrentThreadID())+'_'+random(65536).tostring+'_'+GetHighResTicker.tostring+ '.bat';



    //if the file still exists... it might be because windows is still
    //holding onto the batch file (it may signal that the program is done before
    //it actually closes the batch file....
    while fileexists(sDynamicFile) do begin
      deletefile(PChar(sDynamicFile));
      //we will get around this by renaming our dynamic file if
      //the delete fails.
      if fileexists(sDynamicFile) then begin
        sDynamicFile := extractfilename(sDynamicFile)+'.'+inttohex(GetTicker,8)+'.bat';
      end;
    end;
    result.DynamicFile := sdynamicFile;

    SaveStringAsFile(sDynamicFile, sBat);
    sCommandLine := sDynamicFile;
// sCommandLine := GetAppDataFolder+extractfilename(dllname)+'.bat';
  end;

  FillChar(rProcess, Sizeof(rProcess), 0);
  FillChar(rStartup, Sizeof(_STARTUPINFOW), 0);
  rStartup.cb := Sizeof(_STARTUPINFOW);
  rStartup.lpReserved := nil;
  rStartup.lpDesktop := nil;
  rStartup.lpTitle := nil;
  rStartup.cbReserved2 := 0;
  rStartup.lpReserved2 := nil;

  if bConRedir then
  begin
    rStartup.hStdOutput := hands.stdOUTwrite;
    rStartup.hStdError := hands.stdERRwrite;
    rStartup.hStdInput := hands.stdINread;
  end;

  if bHide then begin
    rStartup.wShowWindow := SW_HIDE;

    if bConRedir then
      rStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW
    else
      rStartup.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  end
  else begin
    rStartup.dwFlags := 0;
  end;

  if bConRedir then
    begin
// rStartup.dwFlags := STARTF_USESHOWWINDOW;
//    rStartup.dwFlags := rStartup.dwFlags or STARTF_USESTDHANDLES;
// rStartup.wShowWindow := SW_HIDE;

  end;

  try
    // showmessage('about to run '+sCommandLine+' from working dir: '+sWkDir);
    // run this ridiculously bloated API call to launch the Executable

    if sWkDir <> '' then begin
      if (copy(sWkDir, length(sWkDir), 1) = '/') or
        (copy(sWkDir, length(sWkDir), 1) = '\') then begin
        sWkDir := copy(sWkDir, 1, length(sWkDir) - 1);

      end;
      ChDir(sWkDir);
    end;

    if bElevate then
      CreateElevateScripts(GetTempPath);

// showmessage('click ok to comtinue');
    // if copy(sCommandLine,1,1) <> '"' then
    // sCommandLine := Quote(sCommandLine);

   if BatchWrap then
     sCommandLine := GetSystemDir+'cmd.exe /C '+sCommandline;
//     sCommandLine := GetSystemDir+'start.exe '+sCommandline;

    cl := nil;
//    if bElevate then
//      sCommandLine := gettemppath+'elevate.cmd '+sCommandLIne;

    cl := PChar(sProg);
    cl2 := PChar(sCommandLine);
    // showmessage('Prog:'+cl+#13#10+'CL:'+sCommandLine);
    if batchwrap then
      cl := cl2;


    //FillChar(rProcess, Sizeof(rProcess), 0);
    if bConredir then begin
      sStartup := rtti_helpers.RecToDebugSTring(@rStartup, typeinfo(_STARTUPINFOW));
      sSec := rtti_helpers.RecToDebugSTring(@Security, typeinfo(TSecurityAttributes));
{$IFDEF DEBUG_EXES}
      Debug.Log('Create process');
      Debug.Log('--startup: '+sStartup);
      Debug.Log('--security attributes: '+sSec);
{$ENDIF}
      var fCreateNoWindow := CREATE_NO_WINDOW;
      if not bhide then
        fCreateNoWindow := 0;

      if CreateprocessW(nil, PChar(cl2), @Security, @Security, true,
{$IFDEF USE_SW_SHOWNA}
        8 or
{$ENDIF}
        priorityclass or fCreateNoWindow, nil, nil, rstartup, rProcess.pi)
        then // PAnsiChar(sWorkingdir)
          result := rProcess;

      if integer(result.pi.hProcess) <= 0 then
        raise Exception.create('Create process failed, for commandline '+cl2+' result = ' + inttostr(result.pi.hProcess)+' error='+inttostr(getlasterror)+newline+sProg+' '+sParams);

    end else begin
      sStartup := rtti_helpers.RecToDebugSTring(@rStartup, typeinfo(_STARTUPINFOW));
      sSec := rtti_helpers.RecToDebugSTring(@Security, typeinfo(TSecurityAttributes));
{$IFDEF DEBUG_EXES}
      Debug.Log('Create process');
      Debug.Log('--startup: '+sStartup);
      Debug.Log('--security attributes: '+sSec);
{$ENDIF}
      var fCreateNoWindow := CREATE_NO_WINDOW;
      if not bhide then
        fCreateNoWindow := 0;
      if CreateprocessW(nil, cl2, @Security, @Security, false,
        priorityclass or fCreateNoWindow, nil, nil, rStartup, rProcess.pi)
        then // PAnsiChar(sWorkingdir)
        result := rProcess;
        if integer(result.pi.hProcess) <= 0 then
          raise Exception.create('Create process failed, for commandline '+cl2+' result = ' + inttostr(result.pi.hProcess)+' error='+inttostr(getlasterror)+newline+sProg+' '+sParams);
    end;
    // StrDispose(cl);
  finally
// CloseHandle(ReadPipe);
// CloseHandle(WritePipe);
  end;
  result := rProcess;
end;

// ------------------------------------------------------------------------------
procedure CloseExe(var hProcessInfo: TBetterProcessInformation);
var
  sDynamicFile: string;
begin
  sDynamicFile := '';
  if hprocessinfo.dynamicfile <> '' then begin
    sDynamicFile :=hProcessinfo.DynamicFile;
  end;

  try
    CloseHandle(hProcessInfo.pi.hProcess);
  except
  end;
  try
    CloseHandle(hProcessInfo.pi.hThread);
  except
  end;

  hProcessInfo.pi.hProcess := INVALID_HANDLE_VALUe;
  hProcessInfo.pi.hthread := INVALID_HANDLE_VALUe;

  try
// while fileexists(sDynamicFile) do begin
//
    if sDynamicFile <> '' then
      if fileexists(sDynamicFile) then
        deletefile(PChar(sDynamicFile));

// if  fileexists(sDynamicFile) then
// sleep(1000);
// end;
  except
  end;

end;
// ------------------------------------------------------------------------------
procedure WaitForEXE(var hProcessInfo: TBetterProcessInformation; bCloseHandle: boolean = true);
// p: hProcessHandle: The process handle of the EXE that is running.
// Waits for an EXE represented by hProcessHandle to exit then returns.
begin

  WaitForSingleObject(hProcessinfo.pi.hProcess, INFINITE);
  if bCloseHandle then begin
    CloseExe(hProcessInfo);
  end;

end;
// ------------------------------------------------------------------------------
function TryWaitForEXE(var hProcessInfo: TBetterProcessInformation): boolean;
// p: hProcessHandle: The process handle of the EXE that is running.
// Waits for an EXE represented by hProcessHandle to exit then returns.
var
  sDynamicFile: string;
begin
  result := true;
  if not(WaitForSingleObject(hProcessInfo.pi.hProcess, 1) = WAIT_OBJECT_0) then begin
    result := false;
    exit;
  end;
  sDynamicFile := 'dynamic_' + inttostr(GetCurrentThreadID()) + '.bat';
  sDynamicFile := slash(GetTempPath) + sDynamicFile;
  CloseExe(hProcessInfo);

  try
    if fileexists(sDynamicFile) then
      deletefile(PChar(sDynamicFile));
  except
  end;

end;

{ TWAitForExeThread }

procedure TWAitForExeThread.DoExecute;
begin
  inherited;
  WaitForEXE(FExehandle);




end;

procedure TWAitForExeThread.Init;
begin
  inherited;
  raise Exception.Create('This is obsolete, you should be using a command');
end;

{ TWaitForExeCommand }

procedure TWaitForExeCommand.DoExecute;
var
  sDynamicFile: string;
begin
  inherited;

  if WaitForSingleObject(self.hProcessInfo.pi.hProcess, 1) = WAIT_TIMEOUT then begin
    KillTaskByID(self.hProcessInfo.pi.dwProcessId);
    if WaitForSingleObject(self.hProcessInfo.pi.hProcess, 1) = WAIT_TIMEOUT then begin
      processlater;
      exit;
    end;
  end;

  sDynamicFile := 'dynamic_' + inttostr(hCreatingThread) + '.bat';
  sDynamicFile := slash(GetTempPAth) + sDynamicFile;
  CloseExe(hProcessInfo);

  try
    if fileexists(sDynamicFile) then
      deletefile(PChar(sDynamicFile));
  except
  end;

end;

procedure ForgetExe(var hProcessInformation: TBetterProcessInformation);
var
  c: TWaitForExeCommand;
begin
  c := TWaitForExeCommand.create;

  c.hProcessInfo := hProcessInformation;
  c.hCreatingThread := GetCurrentThreadID();
  c.OwnedByCommandProcessor := true;
  c.process(ExeCommands);

end;

procedure TWaitForExeCommand.Init;
begin
  inherited;
  Icon := @CMD_ICON_EXe;
end;

procedure TWaitForExeCommand.InitExpense;
begin
  inherited;
  CPUExpense := 0;
end;

{ Tcmd_RunExe }

procedure Tcmd_RunExe.BuildCommandLine;
begin
  //overrideable for descendents
end;



procedure Tcmd_RunExe.CC(ccStatus: TConsoleCaptureStatus; sData: string);
var
  t: ni;
begin
  if ccStatus = ccStart then begin
    FconsoleOutput := '';
    FconsoleTemp := '';
  end;
{$IFDEF DEBUG_EXE_OUTPUT}
  if sData <> '' then
    Debug.Log(sData);
{$ENDIF}
  Status := sData;

  Lock;
  try
    FConsoleDrain := FConsoledrain+sData;
  finally
    Unlock;
  end;

  FConsoleTemp := FConsoleTemp + sData;

  if (ccStatus = ccEnd) or (length(FConsoleTemp) > length(FConsoleOutput)) then begin
    FConsoleOutput := FConsoleOutput + FConsoleTemp;
    FconsoleTemp := '';

  end;



end;

procedure Tcmd_RunExe.CheckIfHungAndTerminate;
begin
  if TimeOut = 0 then exit;

  if GEtTimeSince(LastActiveTime)> Timeout then begin
    TerminateProcess(hProcessInfo.pi.hProcess, 666);
    Hung := true;
  end;

end;

procedure Tcmd_RunExe.ConsoleStatus(cc: TConsoleCaptureStatus; s: string);
begin
  case cc of
    ccProgress:
      Status := s;
  end;
end;

procedure Tcmd_RunExe.DoExecute;
const
 ReadBufferSize = 1048576;  // 1 MB Buffer
//  ReadBufferSize = 4096; // 1 MB Buffer
var
  buffer: PAnsichar;
  sl: TStringLIst;
  BytesRead: DWORD;
  iToREad: integer;
  TotalBytesRead, TotalBytesAvail, BytesLeftThisMessage: integer;
  pTemp: PByte;
  iBufferStart, iBufferEnd: nativeint;
  t: integer;
  tmLastAct: ticker;
  hands: TConsoleHandles;
  apprunning: ni;
  consolestring: string;
  waittime: int64;
begin
  inherited;
  waittime := 1;
  BuildCommandLine;
  Debug.ConsoleLog(FProg+' '+FParams);
  Debug.Log(self,FProg+' '+FParams);
  //ConsoleRedirect := false;
// try
  if PipeDebug then
    batchwrap := true;
  FDebugFile := 'dynamic_' + inttostr(GetCurrentThreadID()) + '.debug';


  if PipeDebug then
    Params := Params + '>' + FDebugFile;

  if ConsoleRedirect then begin
{$IFDEF SEGREGATE_CONSOLE_REDIRECT}
    UseConsoleRedirExecutionPath;
    exit;
{$ENDIF}
  end;
  waittime := 1;

  repeat
  {$IFDEF ALLOW_CONSOLE_REDIRECT}
    if not ConsoleRedirect then begin
      hands.init;
    end else begin
      hands.stdINREAD := INVALID_HANDLE_VALUE;
      hands.stdINWRITE := INVALID_HANDLE_VALUE;
    end;
  {$ELSE}

    ReadPipe := NO_RETURN_HANDLE;
    WritePipe := NO_RETURN_HANDLE;
  {$ENDIF}
    TotalBytesRead := 0;

    Name := Prog+' '+Params;


    hung := false;
    hProcessInfo := RunProgram( hands, Prog, Params,
                                  WorkingDir, Hide, batchwrap, Elevate, PriorityClass);


    Status := 'Exe Started';
    LastActiveTime := GetTicker;

    // GetMem(buffer,  ReadBufferSize);
//    buffer := GetMemory(ReadBufferSize + 1);
    buffer := AllocMem(ReadBufferSize + 1);

    sl := TStringLIst.create;
    try
  {$IFDEF ALLOW_CONSOLE_REDIRECT}
      if ConsoleRedirect then
      try
        cc(ccStart, '');
        tmLastAct := getticker;
        repeat
          // wait for end of child process
          Apprunning := WaitForSingleObject(hProcessInfo.pi.hProcess, waittime);
          if Apprunning <> WAIT_TIMEOUT then begin
//            Debug.Log('app ended');
          end;

          waittime := lesserof(250, waittime*2);

          // it is important to read from time to time the output information
          // so that the pipe is not blocked by an overflow. New information
          // can be written from the console app to the pipe only if there is
          // enough buffer space.


          if not PeekNamedPipe(hands.stdOUTRead, @buffer[TotalBytesRead], ReadBufferSize,
            @BytesRead, @TotalBytesAvail, @BytesLeftThisMessage) then
            break
          else if BytesRead > 0 then begin
            ReadFile(hands.stdOUTRead, buffer[0], BytesRead, BytesRead, nil);
            setlength(consolestring, BytesRead);
            movemem32(@consolestring[strz], buffer, bytesread);
//            consolestring[bytesread] := #0;
//            if zcopy(consolestring, length(consolestring)-2,2) = '#0' then
//              debug.log('here');
            cc(ccProgress, consolestring);
            tmLAstAct := getticker;
            waittime := 1;
            TotalBytesRead := int64(TotalBytesRead) + int64(BytesRead);
          end;

          if not PeekNamedPipe(hands.stdERRRead, @buffer[TotalBytesRead], ReadBufferSize,
            @BytesRead, @TotalBytesAvail, @BytesLeftThisMessage) then
            break
          else if BytesRead > 0 then begin
            ReadFile(hands.stdERRRead, buffer[0], BytesRead, BytesRead, nil);
            setlength(consolestring, BytesRead);
            movemem32(@consolestring[strz], buffer, bytesread);
//            if zcopy(consolestring, length(consolestring)-2,2) = '#0' then
//              debug.log('here');
//            consolestring[bytesread] := #0;
            cc(ccProgress, consolestring);
            tmLAstAct := getticker;
            waittime := 1;
            TotalBytesRead := int64(TotalBytesRead) + int64(BytesRead);
          end;

        until (Apprunning <> WAIT_TIMEOUT) or (GetTimeSince(tmLAstAct) > 300000);

        buffer[TotalBytesRead] := #0;
        // OemToChar(Buffer,Buffer);
        cc(ccEnd, '');
      except
        on E:Exception do begin
          Status := 'Conredir failure:'+e.message;
          FileClose(hands.stdOUTREAD);
          FileClose(hands.stdOUTWRITE);
          FileClose(hands.stdINREAD);
          FileClose(hands.stdINWrite);
          FileClose(hands.stdERRREAD);
          FileClose(hands.stdERRWrite);

          hands.init;
          CloseExe(hProcessInfo);

        end;
      end;
  {$ENDIF}

      //final read

      if hProcessInfo.pi.hProcess <> INVALID_HANDLE_VALUE then
        if not hung then WaitForEXE(hProcessInfo, false);

    finally
      if (hands.stdOutRead <> NO_RETURN_HANDLE) and
        (hands.stdOutWrite  <> NO_RETURN_HANDLE) then begin
        try if hands.stdOutRead  <> NO_RETURN_HANDLE then
            closeHandle(hands.stdOutRead);
        except end;
        try if hands.stdInRead  <> NO_RETURN_HANDLE then
            closeHandle(hands.stdInRead);
        except end;
        try if hands.stdErrRead  <> NO_RETURN_HANDLE then
            closeHandle(hands.stdErrRead);
        except end;
        try if hands.stdOutWrite  <> NO_RETURN_HANDLE then
            closeHandle(hands.stdOutWrite);
        except end;
        try if hands.stdInWrite  <> NO_RETURN_HANDLE then
            closeHandle(hands.stdInWrite);
        except end;
        try if hands.stdErrWrite  <> NO_RETURN_HANDLE then
            closeHandle(hands.stdErrWrite);
        except end;

      end;

      CloseEXe(hProcessinfo);
      FreeMemory(buffer);
      sl.free;
    end;

    if PipeDebug and fileexists(FDebugFile) then begin
      Debug.Log(self,Prog + ' ' + Params + #13#10 + '------' + #13#10 +
          loadstringfromfile(FDebugFile));
      deletefile(PChar(FDebugFile));
    end;
  until Not Hung;

// except
// on E: Exception do begin
      // showmessage(e.Message);
// end;
// end;


end;

function Tcmd_RunExe.DrainConsole: string;
begin
  Lock;
  try
    result := FConsoleDrain;
    FConsoleDrain := '';
  finally
    UNlock;
  end;
end;

function Tcmd_RunExe.GetConsoleOutput: string;
begin
  result := Fconsoleoutput;
  if result <> '' then
    exit;
  result := '';
  if FConsoleOutputPOinter = nil then
    exit;

  result := PWideChar(FConsoleOutputPointer);


end;

procedure Tcmd_RunExe.InitExpense;
begin
  inherited;
  CPUExpense := 0;
  consoleRedirect := true;
end;

procedure Tcmd_RunExe.Init;
begin
  inherited;
  PriorityClass := DEFAULT_PRIORITY_CLASS;
  Icon := @CMD_ICON_EXE;

end;

procedure Tcmd_RunExe.Preprocess;
begin
  inherited;

end;

procedure Tcmd_RunExe.SetIswindowed(const Value: boolean);
begin
  FIsWindowed := Value;
  ConsoleRedirect := false;
  CaptureConsoleoutput := false;
  batchwrap := false;
end;

procedure Tcmd_RunExe.SetProg(const Value: string);
begin
  FProg := Value;
  Name := ExtractFileName(FProg+' '+FParams);
end;

procedure Tcmd_RunExe.Terminate;
begin
  TerminateProcess(self.FExehandle,69);
end;

procedure Tcmd_RunExe.UseConsoleRedirExecutionPath;
begin
  RunAndCapture(self.FProg+' '+self.FParams, self.WorkingDir, cc, Timeout);
end;


procedure RunAndCapture(DosApp: string; wkdir: string; cc: TConsoleCaptureHook; Timeout: ticker; priorityclass: integer = DEFAULT_PRIORITY_CLASS);
// todo merge these capabilities into the other EXE thing
const
  ReadBufferSize = 1048576; // 1 MB Buffer
var
  Security: TSecurityAttributes;

  StdInRead, StdInWrite: THandle;
  StdOutRead, StdOutWrite: THandle;
  ErRead, ErWrite: THandle;
  start: TStartUpInfo;
  ProcessInfo: TBetterProcessInformation;
  buffer: Pansichar;
  TotalBytesRead, BytesRead: DWORD;
  Apprunning, BytesLeftThisMessage, TotalBytesAvail: integer;
  sStartup, sSEC: string;
  consolestring: ansistring;
  waittime: int64;
  tmLastAct: ticker;
  bExitAfterPipeCheck: boolean;
begin
  bExitAfterPipeCheck := false;
  with Security do begin
    FillChar(Security, Sizeof(TSecurityAttributes), #0);
    nlength := Sizeof(TSecurityAttributes);
    binherithandle := true;
    lpsecuritydescriptor := nil;
  end;

  if CreatePipe(StdOutRead, StdOutWrite, @Security, 0) then begin
    CreatePipe(ErRead, ErWrite, @Security, 0);
    CreatePipe(StdInRead, StdInWrite, @Security, 0);
    // Redirect In- and Output through STARTUPINFO structure
//    SetHandleInformation(ReadPipe, HANDLE_FLAG_INHERIT, 0);
//    SetHandleInformation(WritePipe, HANDLE_FLAG_INHERIT, 0);
//    SetHandleInformation(ErRead, HANDLE_FLAG_INHERIT, 0);
//    SetHandleInformation(ErWrite, HANDLE_FLAG_INHERIT, 0);


    buffer := AllocMem(ReadBufferSize + 1);
    FillChar(start, Sizeof(start), #0);

    start.cb := Sizeof(start);
    start.hStdOutput := StdOutWrite;
    start.hStdError := ErWrite;
    start.hStdInput := StdInRead;
    start.dwFlags := STARTF_USESTDHANDLES + STARTF_USESHOWWINDOW;
    start.wShowWindow := SW_HIDE;


    // Create a Console Child Process with redirected input and output

    UniqueString(DosApp);
    sStartup := rtti_helpers.RecToDebugSTring(@start, typeinfo(_STARTUPINFOW));
    sSec := rtti_helpers.RecToDebugSTring(@Security, typeinfo(TSecurityAttributes));
{$IFDEF DEBUG_EXES}
    Debug.Log('Create process');
    Debug.Log('--startup: '+sStartup);
    Debug.Log('--security attributes: '+sSec);
{$ENDIF}
    var pc: PChar := nil;
    if wkdir <> '' then
      pc := PChar(wkdir);
    var fCreateNoWindow := CREATE_NO_WINDOW;
    if CreateprocessW(nil, PChar(DosApp), @Security, @Security, true,
{$IFDEF USE_SW_SHOWNA}
      8 or
{$ENDIF}
      priorityclass or fCreatenoWindow, nil, pc, start, ProcessInfo.pi) then begin
      TotalBytesRead := 0;
      cc(ccStart, '');
      waittime := 1;
      tmLAstAct := getticker;
      repeat

        // wait for end of child process
        Apprunning := WaitForSingleObject(ProcessInfo.pi.hProcess, waittime);
        waittime := lesserof(waittime * 2, 250);
        if Apprunning <> WAIT_TIMEOUT then begin
          Debug.Log('app ended');
          bExitAfterPipeCheck := true;
        end;
        // it is important to read from time to time the output information
        // so that the pipe is not blocked by an overflow. New information
        // can be written from the console app to the pipe only if there is
        // enough buffer space.


        repeat
          BytesRead := 0;
          if not PeekNamedPipe(STdoutRead, @buffer[0], ReadBufferSize,
            @BytesRead, @TotalBytesAvail, @BytesLeftThisMessage) then
            Debug.Log('Could not peek std pipe')
          else if BytesRead > 0 then begin
            ReadFile(STdoutRead, buffer[0], BytesRead, BytesRead, nil);
            setlength(consolestring, BytesRead);
            movemem32(@consolestring[strz], buffer, bytesread);
//            consolestring[bytesread] := #0;
            cc(ccProgress, string(consolestring));
            tmLastAct := getticker;
            waittime := 1;
          end;
        until BytesRead = 0;
        TotalBytesRead := TotalBytesRead + BytesRead;

        repeat
          BytesRead := 0;
          if not PeekNamedPipe(ErRead, @buffer[0], ReadBufferSize,
            @BytesRead, @TotalBytesAvail, @BytesLeftThisMessage) then
            Debug.Log('Could not peek err pipe')
          else if BytesRead > 0 then begin
            ReadFile(ErRead, buffer[0], BytesRead, BytesRead, nil);
            setlength(consolestring, BytesRead);
            movemem32(@consolestring[strz], buffer, bytesread);
//            consolestring[bytesread] := #0;
            cc(ccProgress, string(consolestring));
            tmLastAct := getticker;
            waittime := 1;
          end;
          TotalBytesRead := TotalBytesRead + BytesRead;
        until BytesRead = 0;


      until (Apprunning <> WAIT_TIMEOUT) or ((timeout > 0) and (gettimesince(tmLAstAct)>TimeOut));

      if ((gettimesince(tmLAstAct)>TimeOut) and (Timeout>0)) then begin
        Debug.Log('cancel because hang/no output');
        KillTaskByID(processinfo.pi.dwProcessID);
      end;

      // OemToChar(Buffer,Buffer);
//      cc(ccProgress, strpas(buffer));
      cc(ccEnd, '');

    end;
    FreeMem(buffer);
    if ProcessInfo.pi.hProcess <> INVALID_HANDLE_VALUE then
      CloseHandle(ProcessInfo.pi.hProcess);
    if ProcessInfo.pi.hThread <> INVALID_HANDLE_VALUE then
      CloseHandle(ProcessInfo.pi.hThread);

    if STdoutRead <> INVALID_HANDLE_VALUE then
      CloseHandle(STdoutRead);
    if STdoutWrite <> INVALID_HANDLE_VALUE then
      CloseHandle(STdoutWrite);

    if STdinRead <> INVALID_HANDLE_VALUE then
      CloseHandle(STdinRead);
    if STdinWrite <> INVALID_HANDLE_VALUE then
      CloseHandle(STdinWrite);

    if ErRead <> INVALID_HANDLE_VALUE then
      CloseHandle(ErRead);
    if ErWrite <> INVALID_HANDLE_VALUE then
      CloseHandle(ErWrite);
  end;

  Debug.Log('Done processing EXE output');
end;

{ TBetterProcessInformation }

procedure TBetterProcessInformation.Init;
begin
  fillmem(pbyte(@pi), sizeof(pi), 0);
  pi.hProcess := INVALID_HANDLE_VALUE;
  pi.hThread := INVALID_HANDLE_VALUE;

  DynamicFile := '';
end;


{ TConsoleHandles }

procedure TConsoleHandles.Init;
begin
  stdINread := NO_RETURN_HANDLE;
  stdINread := NO_RETURN_HANDLE;
  stdOUTRead := NO_RETURN_HANDLE;
  stdOUTWrite := NO_RETURN_HANDLE;
  stdERRread := NO_RETURN_HANDLE;
  stdERRWrite := NO_RETURN_HANDLE;

end;

function RunExeAndCapture(app: string; params: string = ''; wkdir: string = ''): string;
var
  c: Tcmd_RunExe;
begin
  c := Tcmd_RunExe.Create;
  try
    c.Prog := app;
    c.Params := params;
    c.CaptureConsoleoutput := true;
    c.WorkingDir := wkdir;
    c.Start;
    c.WaitFor;
    result := c.ConsoleOutput;
  finally
    c.free;
    c := nil;
  end;

end;

function GetProcessList(exeNameORFullPathNameIfYouWantToCheckSpecificPath: string; iForceCount: ni = 0): Tarray<TProcessInfo>;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  proc: TProcessInfo;
begin
  var exepath := extractfilepath(exeNameORFullPathNameIfYouWantToCheckSpecificPath);
  var exeName := extractfilename(exeNameORFullPathNameIfYouWantToCheckSpecificPath);
  setlength(result,0);
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  try
    FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
    ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
    while Integer(ContinueLoop) <> 0 do
    begin
      proc.init;
      proc.ExeName := exeName;

      if 0=comparetext(ExtractFileName(FProcessEntry32.szExeFile),exeName)
      then
      begin
        proc.pid := FProcessEntry32.th32ProcessID;
        var fullpath := proc.fullpath;
        if (exePath = '') //<<---- no path specified, returns ALL instances regardless of path
        or (UpperCase(ExtractFilePath(fullpath)) = UpperCase(exePath)) then begin
          proc.running := True;
          Debug.Log(exeName + ' is running @'+FullPath);

          try
            proc.fileDate := GetfileDate(FullPath);
          except
            proc.filedate := 0.0;
          end;
          inc(proc.runningCount);
          setlength(result, length(result)+1);
          result[high(result)] := proc;
        end;
      end;
      ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
    end;
  finally
    CloseHandle(FSnapshotHandle);
  end;
  if length(result) < iForceCount then begin
    var x := length(result);
    setlength(result, iForcecount);
    for var t := x to high(result) do begin
      result[t].Init;
      result[t].ExeName := exeNAme;
    end;
  end;
end;


function GetProcessInfo(exeFileName: string): TProcessInfo;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  result.init;
  result.ExeName := exeFileName;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  try
    FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
    ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
    while Integer(ContinueLoop) <> 0 do
    begin
      if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
        UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
        UpperCase(ExeFileName))) then
      begin
        //WriteLog(exeFileName + ' is running');
        Result.running := True;
        result.pid := FProcessEntry32.th32ProcessID;
//        result.FullPath := FProcessEntry32.szExeFile;
        result.fileDate := GetfileDate(result.FullPath);
        inc(result.runningCount);

      end;
      ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
    end;
  finally
    CloseHandle(FSnapshotHandle);
  end;
end;

function processExists(exeFileName: string): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := False;
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
    begin
      //WriteLog(exeFileName + ' is running');
      Result := True;
      break;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function ServiceGetStatus(sMachine, sService: PChar): DWORD;
  {******************************************}
  {*** Parameters: ***}
  {*** sService: specifies the name of the service to open
  {*** sMachine: specifies the name of the target computer
  {*** ***}
  {*** Return Values: ***}
  {*** -1 = Error opening service ***}
  {*** 1 = SERVICE_STOPPED ***}
  {*** 2 = SERVICE_START_PENDING ***}
  {*** 3 = SERVICE_STOP_PENDING ***}
  {*** 4 = SERVICE_RUNNING ***}
  {*** 5 = SERVICE_CONTINUE_PENDING ***}
  {*** 6 = SERVICE_PAUSE_PENDING ***}
  {*** 7 = SERVICE_PAUSED ***}
  {******************************************}
var
  SCManHandle, SvcHandle: SC_Handle;
  SS: TServiceStatus;
  dwStat: DWORD;
begin
  dwStat := 0;
  // Open service manager handle.
  SCManHandle := OpenSCManager(sMachine, nil, SC_MANAGER_CONNECT);
  if (SCManHandle > 0) then
  begin
    SvcHandle := OpenService(SCManHandle, sService, SERVICE_QUERY_STATUS);
    // if Service installed
    if (SvcHandle > 0) then
    begin
      // SS structure holds the service status (TServiceStatus);
      if (QueryServiceStatus(SvcHandle, SS)) then
        dwStat := ss.dwCurrentState;
      CloseServiceHandle(SvcHandle);
    end;
    CloseServiceHandle(SCManHandle);
  end;
  Result := dwStat;
end;

{ TProcessInfo }


function GetFullPathFromPID(PID: DWORD): string;
begin
  result := GetFileNameByProcessID(pid);
end;
(*var
  hProcess: THandle;
  ModName : Array[0..MAX_PATH + 1] of Char;
begin
 Result:='';
  hProcess := OpenProcess(PROCESS_ALL_ACCESS,False, PID);
  try
    if hProcess <> 0 then
     if GetModuleFileName(hProcess, ModName, Sizeof(ModName))<>0 then
       Result:=ModName
      else
       result := SysErrorMessage(GetLastError);
  finally
   CloseHandle(hProcess);
  end;
end;*)


function TProcessInfo.FullPath: string;
begin
  try
    result := GEtFullPathFromPID(self.pid);
  except
    on E: Exception do begin
      result := '*'+e.message;
    end;
  end;
end;

function TProcessInfo.handlecount: ni;
var
  handles: cardinal;
begin
  try
    result := 0;
    var HProcess := INVALID_HANDLE_VALUE;
    HProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, pid);
    try
      if GetProcessHandleCount(HProcess, handles) then
        result := handles
      else
        raise ECritical.create(SysErrorMessage(GetLastError));
    finally
      if hProcess <> INVALID_HANDLE_VALUE then
        CloseHandle(hProcess);
    end;
  except
    on E: Exception do begin
      result := 0;
    end;
  end;
end;

procedure TProcessInfo.Init;
begin
  Running := false;
  RunningCount := 0;
  fileDate := 0.0;
  ExeName := '';
//  FullPath := '';
end;







function IsWindows200OrLater: Boolean;
begin
  Result := Win32MajorVersion >= 5;
end;

function IsWindowsVistaOrLater: Boolean;
begin
  Result := Win32MajorVersion >= 6;
end;


procedure DonePsapiLib;
begin
  if PsapiLib = 0 then Exit;
  FreeLibrary(PsapiLib);
  PsapiLib := 0;
  @GetModuleFileNameExW := nil;
end;

procedure InitPsapiLib;
begin
  if PsapiLib <> 0 then Exit;
  PsapiLib := LoadLibrary('psapi.dll');
  if PsapiLib = 0 then RaiseLastOSError;
  @GetModuleFileNameExW := GetProcAddress(PsapiLib, 'GetModuleFileNameExW');
  if not Assigned(GetModuleFileNameExW) then
    try
      RaiseLastOSError;
    except
      DonePsapiLib;
      raise;
    end;
end;

function GetFileNameByProcessID(AProcessID: DWORD): UnicodeString;
const
  PROCESS_QUERY_LIMITED_INFORMATION = $00001000; //Vista and above
var
  HProcess: THandle;
  Lib: HMODULE;
  QueryFullProcessImageNameW: TQueryFullProcessImageNameW;
  S: DWORD;
begin
  if IsWindowsVistaOrLater then
    begin
      Lib := GetModuleHandle('kernel32.dll');
      if Lib = 0 then RaiseLastOSError;
      @QueryFullProcessImageNameW := GetProcAddress(Lib, 'QueryFullProcessImageNameW');
      if not Assigned(QueryFullProcessImageNameW) then RaiseLastOSError;
      HProcess := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, AProcessID);
      if HProcess = 0 then RaiseLastOSError;
      try
        S := MAX_PATH;
        SetLength(Result, S + 1);
        while not QueryFullProcessImageNameW(HProcess, 0, PWideChar(Result), S) and (GetLastError = ERROR_INSUFFICIENT_BUFFER) do
          begin
            S := S * 2;
            SetLength(Result, S + 1);
          end;
        SetLength(Result, S);
        Inc(S);
        if not QueryFullProcessImageNameW(HProcess, 0, PWideChar(Result), S) then
          RaiseLastOSError;
      finally
        CloseHandle(HProcess);
      end;
    end
  else
    if IsWindows200OrLater then
      begin
        InitPsapiLib;
        HProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, AProcessID);
        if HProcess = 0 then RaiseLastOSError;
        try
          S := MAX_PATH;
          SetLength(Result, S + 1);
          if GetModuleFileNameExW(HProcess, 0, PWideChar(Result), S) = 0 then
            RaiseLastOSError;
          Result := PWideChar(Result);
        finally
          CloseHandle(HProcess);
        end;
      end;
end;

{$ENDIF}

{$IFDEF MSWINDOWS}
function GetAllServices: TArray<TServiceInfo>;
var
  l,r: string;
  nurec: TServiceInfo;
  res: TArray<TServiceInfo>;
  procedure CommitRec;
  begin
    if nurec.filled then begin
      setlength(res, length(res)+1);
      res[high(res)] := nurec;
    end;
  end;
begin

//  var sTasks := exe.RunExeAndCapture(getsystemdir+'tasklist.exe');
//  result := stringtostringlisth(sTasks);
  var c := Tcmd_RunExe.create;
  try
    c.Prog := getsystemdir+'sc.exe';
    c.Params := 'query type= service state= all';
    c.batchwrap := true;
//    c.CaptureConsoleoutput := true;
    c.start;
    c.Hide := true;
    c.WaitFor;
    var services := c.ConsoleOutput;

    var temp := stringToStringListH(services);

    setlength(result,0);


    for var t := 0 to temp.o.Count-1 do begin
(*
SERVICE_NAME: Appinfo
DISPLAY_NAME: Application Information
        TYPE               : 30  WIN32
        STATE              : 4  RUNNING
                                (STOPPABLE, NOT_PAUSABLE, IGNORES_SHUTDOWN)
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0
*)

      if SplitString(temp.o[t], ':', l,r) then begin
        l := trim(l);
        r := trim(r);
        if l = 'SERVICE_NAME' then begin
          CommitRec;
          nurec.Init;
          nurec.Name := r;
        end;
        if l = 'DISPLAY_NAME' then begin
          nurec.DisplayName := r;
        end;
        if l = 'STATE' then begin
          nurec.State := r;
        end;
      end;
    end;
    CommitRec;

  finally
    c.Free;
  end;

  result := res;

end;
{$ENDIF}

procedure oinit;
begin
{$IFDEF MSWINDOWS}
  ExeCommands := TCommandProcessor.create(BackGroundThreadMan, 'ExeCommands');
{$ENDIF}
end;

procedure ofinal;
begin
{$IFDEF MSWINDOWS}
  ExeCommands.free;
  ExeCommands := nil;
{$ENDIF}

end;




{ TRunningTask }
{$IFDEF MSWINDOWS}
function TRunningTask.fileDate: TDateTime;
begin
  result := 0.0;
  try
    result := GetfileDate(self.FullExeName);
  except
  end;
end;

function TRunningTask.HandleCount: ni;
var
  handles: cardinal;
begin
  result := 0;
  var HProcess := INVALID_HANDLE_VALUE;
  HProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, processid);
  try
    if GetProcessHandleCount(HProcess, handles) then
      result := handles
    else
      raise ECritical.create(SysErrorMessage(GetLastError));
  finally
    if hProcess <> INVALID_HANDLE_VALUE then
      CloseHandle(hProcess);
  end;
end;


procedure TRunningTask.Init;
begin
  exeName := 'Unknown';
  Parameters := '';
  processid := -1;
end;

class operator TRunningTask.notequal(a,b: TRunningTask): boolean;
begin
  if a.exeName <> b.exeName then exit(false);
  if a.FullExeName <> b.FullExeName then exit(false);
  if a.Parameters <> b.Parameters then exit(false);
  if a.processid <> b.processid then exit(false);
  exit(true);
end;

{$ENDIF}

{ TServiceInfo }

{$IFDEF MSWINDOWS}
function TServiceInfo.filled: boolean;
begin
  result := state <> '';
end;

procedure TServiceInfo.Init;
begin
  DisplayName := '';
  Name := '';
  State := '';
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
function GetServicesNamed(sName: string): TArray<TServiceInfo>;
var
  a: TArray<TServiceInfo>;
begin
  a := GetAllServices();
  setlength(result, 0);
  for var t := 0 to high(a) do begin
    if (0=comparetext(a[t].DisplayName, sName))
    or (0=comparetext(a[t].Name, sName)) then begin
      setlength(result, length(result)+1);
      result[high(result)] := a[t];
    end;
  end;
end;


function IsServiceInstalled(sName: string): boolean;
begin
  result := length(GetServicesNamed(sNAme)) > 0;

end;
{$ENDIF}


procedure CleanDynamicFolder;
{$IFDEF MSWINDOWS}
var
  fil: TFileInformation;
begin
  try
    var dir := TDirectory.create(slash(systemx.GetTempPath), 'dynamic_*.bat', 0,0, true, false);
    try
      while dir.getnextfile(fil) do begin
        if fil.Date < (now()-1.0) then begin
          try
            deletefile(pchar(fil.FullName));
          except
          end;
        end;
      end;
    finally
    end;
  except
  end;
end;
{$ELSE}
begin
//  raise ECritical.create('unimplemented');
//TODO -cunimplemented: unimplemented block
end;
{$ENDIF}


initialization
  init.RegisterProcs('exe', oinit, ofinal, 'ManagedThread');



finalization
{$IFDEF MSWINDOWS}
  DonePsapiLib;
{$ENDIF}


end.

