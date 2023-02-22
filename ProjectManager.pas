unit ProjectManager;

interface

uses
  typex, systemx, threadmanager, managedthread,commandprocessor, webconfig, debug, diagram, sysutils, SharedObject, PascalCompiler,  BackgroundThreads, classes, docgen, generics.collections, orderlyinit, betterobject;

type
  TProjectManager = class(TLockQueuedObject)
  private
    FProjects: TList<TUMLProject>;
    FBaseDir: string;

    function Getbasedir: string;
    procedure SetBaseDir(const Value: string);
    function GetProjects(idx: integer): TUMLProject;
  public
    constructor create;override;
    destructor Destroy;override;

    property BaseDir: string read Getbasedir write SetBaseDir;

    property Projects[idx: integer]: TUMLProject read GetProjects;
    function AddProject: TUMLProject;
    function IndexOfProject(p: TUMLProject): integer;
    function HasProject(p: TUMLProject): boolean;
    procedure RemoveProject(p: TUMLProject);
    function ProjectCount: integer;


    procedure Scan;
    procedure refresh;
  end;

  TCompileCommand = class(TCommand)
  private
    FProject: TUMLProject;
  public
    property Project: TUMLProject read FProject write FProject;
    procedure DoExecute;override;
    procedure OnCompileProgress(pos, max: integer);

  end;

  TProjectManagerThread = class(TManagedThread)
  private
    FRedo: boolean;
    function GetRedo: boolean;
    procedure SEtRedo(const Value: boolean);
  protected
    FPM: TProjectmanager;
  published
  public
    procedure QueueCommands;
    procedure DoExecute;override;
    procedure BuildMenu;override;
    constructor Create(Owner: TObject; Manager: TThreadManager; pool: TThreadPoolBase);override;
    procedure MenuAction(idx: NativeInt); override;
    property Redo: boolean read GetRedo write SEtRedo;
    procedure BeforeCheckCommands;
  end;


function PM: TProjectManager;
procedure AssertProjectExists;

var
  pmt: TProjectManagerThread = nil;

implementation

function PM: TProjectManager;
begin
  repeat
    result := pmt.FPM;
    if result = nil then sleep(1000);
  until result <> nil;
end;

{ TProjectManager }

function TProjectManager.AddProject: TUMLProject;
begin
  Lockwrite;
  try
    result := TUMLProject.create;
    FProjects.add(result);
  finally
    Unlockwrite;
  end;
end;

constructor TProjectManager.create;
begin
  inherited;
  FProjects := TList<TUMLProject>.create;
end;

destructor TProjectManager.Destroy;
begin
  FProjects.free;
  inherited;
end;

function TProjectManager.Getbasedir: string;
begin
  LockString;
  try
    result := FBaseDir;
    
  finally
    UnlockString;
  end;
end;

function TProjectManager.GetProjects(idx: integer): TUMLProject;
begin
  LockRead;
  try

    result := FProjects[idx];
  finally
    UnlockRead;
  end;
end;

function TProjectManager.HasProject(p: TUMLProject): boolean;
begin
  result := IndexOfProject(p) >=0;
end;

function TProjectManager.IndexOfProject(p: TUMLProject): integer;
var
  i: integer;
begin
  result := -1;
  LockRead;
  try
    result := FProjects.indexof(p);
  finally
    unlockRead;
  end;

end;

function TProjectManager.ProjectCount: integer;
begin
  LockRead;
  try
    result := FProjects.count;
  finally
    UnlockRead;
  end;

end;

procedure TProjectManager.refresh;
begin
  LockWrite;
  try

  finally
    UnlockWrite;
  end;
end;

procedure TProjectManager.RemoveProject(p: TUMLProject);
begin
  LockWrite;
  try
    FProjects.remove(p);
  finally
    UnlockWrite;
  end;

end;

procedure TProjectManager.Scan;
var
  t: integer;
begin
  Lockwrite;
  try
    for t:= 0 to ProjectCount-1 do begin
      Projects[t].CompileQueue;
    end;
  finally
    Unlockwrite;
  end;

//TODO -cunimplemented: unimplemented block
end;

procedure TProjectManager.SetBaseDir(const Value: string);
begin



//TODO -cunimplemented: unimplemented block
end;

{ TProjectManagerThread }

procedure TProjectManagerThread.BeforeCheckCommands;
begin
  inherited;
  If Redo then begin
    Redo := false;
    QueueCommands;

  end;
end;

procedure TProjectManagerThread.BuildMenu;
begin
  inherited;
  AddMenuItem('Refresh');
end;

constructor TProjectManagerThread.Create(Owner: TObject; Manager: TThreadManager; pool: TThreadPoolBase);
var
  p: TUMLProject;
  cc: TCompileCommand;
begin
  inherited;
  FPM := TProjectManager.create;

  Redo := true;

end;

procedure TProjectManagerThread.DoExecute;
var
  p: TUMLProject;
begin
  inherited;

  if paramstr(1) = 'test' then begin
    p := FPM.AddProject;
    p.Name := 'parsetest';
    p.AddSourceDir(dllpath+'..\parsetest', '*.pas', false);
  end else begin
    p := FPM.AddProject;

    p.Name := 'codedb';

  //  GLOG.Filter := '';
  //  p.AddSourceDir('G:\focus\komodo\drivers\decoders\micronas', '*.h', true);
  //  p.AddSourceFile('g:\focus\komodo\drivers\decoders\micronas\include\_aaa.h');
    p.AddSourceDir(dllpath+'..\commonx', '*.pas', false);
    p.AddSourceDir(dllpath+'..\commonx\vcl', '*.pas', false);
    p.AddSourceDir(dllpath+'..\commonx\fmx', '*.pas', false);
  end;


//  p.AddSourceFile(dllpath+'..\commonx\systemx.pas');
{$IFNDEF NO_PM_COMPILE}
  QueueCommands;
{$ENDiF}






end;



function TProjectManagerThread.GetRedo: boolean;
begin
  Lock;
  try
    result := FRedo;
  finally
    Unlock;
  end;
end;

procedure TProjectManagerThread.MenuAction(idx: nativeint);
begin
  inherited;
  case idx of
    MT_MENU_INDEX+0: Redo := true;
  end;
end;

procedure TProjectManagerThread.QueueCommands;
var
  p: TUMLProject;
  sDir: ansistring;
  cc: TCompileCommand;
begin

  FPM.LockWrite;
  try
    FPM.BaseDir := dllpath+'..\';

    cc := TCompileCommand.create;
    cc.Project := FPM.Projects[0];      //todo 1: unfinished
    cc.FireForget := false;
    cc.start;
    cc.waitfor;
    cc.Free;


  finally
    FPM.UnlockWrite;
  end;

end;

procedure TProjectManagerThread.SEtRedo(const Value: boolean);
begin
  Lock;
  try
    FRedo := value;
  finally
    Unlock;
  end;
end;

{ TCompileCommand }

procedure TCompileCommand.DoExecute;
var
  sDir: ansistring;
begin
  inherited;
  RaiseExceptions := false;
  project.OnProgress := self.OnCompileProgress;
  project.clear;
  project.compileall;

  Debug.Log('Compile Complete!');
  sDir := dllpath+'HTML\Projects\0\';
  ForceDirectories(sDir);
  Debug.Log('Generating HTML documentation');

  docgen.ProjectToHTML(sDir, project);
  step := stepcount;

end;

procedure TCompileCommand.OnCompileProgress(pos,max: integer);
begin
  if tryLock then
  try
    stepcount := max;
    step := pos; 
  finally
    Unlock;
  end;

  if self.Processor.TryLock(4000) then 
  try
//    processor. := max;
//    processor.Step:= pos;
  finally
    self.Processor.unlock;
  end;

end;



procedure AssertProjectExists;
begin
  if PM.ProjectCount =0 then
    raise ECritical.create('no project was defined.');
end;

procedure oinit;
begin
  pmt := TPM.NeedThread<TProjectManagerThread>(nil);
//  pmt.beginstart;
end;

procedure ofinal;
begin
  if assigned(pmt) then begin
    pmt.Stop;
    pmt.SafeWaitFor;
    TPM.NoNeedThread(pmt);
  end;
end;

initialization

orderlyinit.init.RegisterProcs('ProjectManager', oinit, ofinal, 'ManagedThread');




end.
