unit SimpleQueue;
//Prove:
//[ ] Things are added to the queue, queue marked hot.
//[ ] Queue runs
//[ ] Queue empties incoming
//[ ] queue adds to working
//[ ] queue moves to complete (unless autodestroy)
//[ ] Queue items are completed

{$I DELPHIDEFS.inc}
{x$DEFINE EXECUTE_ON_ADD}

interface

uses
{$IFDEF WINDOWS}
  {$IFDEF FPC}
    windows,
  {$ELSE}
    winapi.windows,//inline
  {$ENDIF}
{$ENDIF}
  classes, sysutils, debug, linked_list, numbers, ringstats,
  typex, systemx, better_collections, signals, betterobject, sharedobject, managedthread, tickcount;


const
  QUEUE_SPIN = 0;
  MQ_START_COUNT = 0;
type
  TAbstractSimpleQueue = class;//forward



  TQueueItem = class;//forward

  TQueueItemFinishedProc = reference to procedure (qi: TQueueItem);

  TQueueItem = class(TBetterObject)
  strict private
    function GEtWait: boolean;inline;
  strict
  private
    FQueue: TAbstractSimpleQueue;
    FAutoDestroy: boolean;
  private
    FAllowSynchronous: boolean;
  protected
      procedure DoExecute;virtual;
  public
    wasexecuted: boolean;
    FWaitSignal: TSignal;
    tmUSerMarker: ticker;
    onFinish_Anon: TQueueItemFinishedProc;
    cancelled: boolean;
    constructor Create;override;
    procedure Init;override;
    procedure Detach;override;
    Destructor Destroy;override;
    property Wait: boolean read GEtWait;
    function WAitFor(iTimeout: ni = -1): boolean;
    procedure Execute;virtual;
    procedure SignalComplete;inline;
    property AutoDestroy: boolean read FAutoDestroy write FAutoDestroy;
    function IsComplete   : boolean;inline;
    property Queue: TAbstractSimpleQueue read FQueue write FQueue;
    function DebugString: string;virtual;
    property AllowSynchronous: boolean read FAllowSynchronous write FAllowSynchronous;
  end;


  TIndirectlyLinkableQueueItem = class(TQueueItem, IIndirectlyLinkable<TIndirectlyLinkableQueueItem>)
  private
    indirectlinkage: array of TLinkage<TIndirectlyLinkableQueueItem>;
    function GetLinkageFor(obj: TObject): TLinkage<TIndirectlyLinkableQueueItem>;
    procedure AddLinkage(link: TLinkage<TIndirectlyLinkableQueueItem>; list: TObject);
    procedure RemoveLinkage(list: TObject);
  end;

  TAnonymousQueueProc = reference to procedure;

  TAnonymousQueueItem = class(TQueueItem)
  private
    FAnonMethod: TAnonymousQueueProc;
  protected
    procedure DoExecute; override;
  public
    procedure Init; override;
    property AnonMethod: TAnonymousQueueProc read FAnonMethod write FAnonMethod;
  end;


  TQueueItemList = class(TDirectlyLinkedList_Shared<TQueueItem>);


  TAbstractSimpleQueue = class(TManagedThread)
  private
    FExecuteLock: TCLXCriticalSection;
    FMaxItemsInQueue: ni;
    FBlockIncoming: boolean;
    no_workable_items: boolean;
    FAutoMaintainIdleInterval: boolean;
    FOnEmpty: TNotifyEvent;
    FEnableItemDebug: boolean;
    FOnNotEmpty: TNotifyEvent;
    FTotalActiveTime: int64;
    FActiveNow: boolean;
    FAONEmpty: TProc;
    procedure ProcessItem;virtual;abstract;

    procedure BlockIncoming;
    procedure UnBlockIncoming;
    function CollectIncoming(bForce: boolean): boolean;
    function GetHold: boolean;
    procedure SetHold(const Value: boolean);
    procedure CheckWorkingItems;inline;
  protected
    tmLastCollection: ticker;
    FIterations: nativeint;
    FIncomingItems, FWorkingItems{$IFDEF TRACK_COMPLETED}, FCompletedItems{$ENDIF}: TDirectlyLInkedList_Shared<TQueueItem>;
    last_process_time: int64;
    FWorkingIndex: nativeint;
    function GetNextItem: TQueueItem;virtual;
    function IdleBreak: Boolean; override;
    procedure AfterUrgentCopy;virtual;
  public
    evQueueIdle: TSignal;
    shutdown: boolean;
    evHold: TSignal;
    evNotCongested: TSignal;
    urgent: boolean;
    sidefetches: int64;
    estimated_backlog_size: nativeint;
    estimated_queue_size: nativeint;
    running_synchronous: boolean;
    status_time: ticker;
    keepSTats: boolean;
    hits, misses: int64;
    rs: TRingSTats;
    rsAdd,rsAddLock,rsAddExtras: TringStats;
    rsIdle: TRingStats;
    idleTick: ticker;
    procedure Init;override;
    procedure InitFromPool;override;
    destructor Destroy;override;
    procedure SetStartingState;override;
    procedure Detach;override;
    procedure AfterProcessItem;virtual;
    procedure AddItem(itm: TQueueItem);inline;
    procedure AddItemQuick(itm: TQueueItem);inline;
    procedure RemoveCompletedItem(itm: TQueueItem);inline;
    procedure DoExecute;override;
    procedure ExecuteLock;inline;
    procedure ExecuteUnlock;inline;
    function TryExecuteLock: boolean;inline;
    procedure ProcessAllSynchronously;
    procedure WaitForAll;
    function Stop(bySelf: boolean=false): boolean; override;
    procedure OnPrepareToStop; override;
    property MaxItemsInQueue: ni read FMaxItemsInQueue write FMaxItemsInQueue;
    procedure OptimizeIncoming(var incomingitem: TQueueItem);virtual;
    procedure WaitForFinish;override;
    property Hold: boolean read GetHold write SetHold;
    procedure UpdateStatus(bForce: boolean);inline;

{$IFDEF TRACK_COMPLETED}
    property CompletedItems: TDirectlyLinkedList_Shared<TQueueItem> read FCompletedItems;
{$ENDIF}
    function EstimatedSize: ni;inline;
    property AutoMaintainIdleInterval: boolean read FAutoMaintainIdleInterval write FAutoMaintainIdleInterval;
    procedure SelfAdd(qi: TQueueItem);
    property OnEmpty: TNotifyEvent read FOnEmpty write FOnEmpty;
    property AOnEmpty: TProc read FAONEmpty write FAONEmpty;
    property OnNotEmpty: TNotifyEvent read FOnNotEmpty write FOnNotEmpty;
    function QueueFull: boolean;
    property EnableItemDebug: boolean read FEnableItemDebug write FEnableItemDEbug;
    procedure DropPending;

  end;

  TFakeCommand = class(TQueueItem)
  private
    FJunkFloat: nativefloat;
    function GEtStatus: string;
    procedure SetStatus(Value: string);
  protected


    procedure InitExpense;virtual;
    procedure Start(queue: TAbstractSimpleQueue);
    property cpuexpense: nativefloat read FJunkFloat write FJunkFloat;
    property Status: string read GEtStatus write SetStatus;

  end;

  TSimpleQueue = class(TAbstractSimpleQueue)
  protected
    procedure ProcessItem;override;
  public
    function QueueAnonymous(bAutoDestroy: boolean; proc: TAnonymousQueueProc): TAnonymousQueueItem;

  end;

  TMultiQueue = class(TSharedObject)
  private
    FMaxItemsInQueue: ni;
    function estimated_backlog_size: ni;
    procedure SetMaxItemsInQueue(const Value: ni);
    procedure CheckGrowQueueThreads;
  protected
    growfinished: boolean;
    rridx: ni;
    evEmptyAvailable: TSignal;
    FList: TBetterList<TSimpleQueue>;
    function GetShortestQueue: TSimpleQueue;
    procedure QueueOnEmpty(sender: TObject);
  public
    RoundRobin: boolean;
    constructor Create;override;
    destructor Destroy;override;
    procedure AddItem(itm: TQueueItem);virtual;
    procedure Start;
    function estimated_queue_size: ni;
    function EstimatedSize: ni;inline;
    function WaitForEmptyQueue(iTimeout: ni = 100): TSimpleQueue;
    procedure WaitForAllQueues;
    property MaxItemsInQueue: ni read FMaxItemsInQueue write SetMaxItemsInQueue;
  end;


  TqiAddQueueItem = class(TQueueItem)
  protected
    procedure DoExecute; override;
  public
    qi: TQueueItem;
    q: TAbstractSimpleQueue;

  end;




implementation


{ TAbstractSimpleQueue }


{ TAbstractSimpleQueue<T_ITEM> }



procedure TAbstractSimpleQueue.AddItem(itm: TQueueItem);
var
  bWait: boolean;
  bGotWork: boolean;
  bCanSync: boolean;
  tm, tm2: ticker;
  sleeptime: ticker;
begin

{$IFDEF EXTRA_CHECKS}
  if itm.IsDead then
    raise Ecritical.create('trying to add a dead '+itm.classname);
{$ENDIF}

  WaitForSignal(evNotCongested,1000);

  //Debug.Log(self, 'Add item to '+self.NameEx);
  if shutdown then
    raise ECritical.create('Queue is shut down');
//  Debug.log(self, 'Added '+itm.DebugString);
  //SPECIAL SYNCHRONOUS CODE
  if itm.AllowSynchronous then begin
    bGotWOrk := false;
    if estimated_queue_size = 0 then begin
      if assigned(FOnNotEmpty) then
        FOnNotEmpty(self);//!!!!!!NOT UNDER LOCK

    end;

    if estimated_queue_size + estimated_backlog_size = 0 then begin
      FIncomingItems.lock;
      bGotWork := FWorkingItems.TryLock;
      bCanSync := ((FWorkingItems.countvolatile + FIncomingItems.countvolatile) = 0) and (running_synchronous = false);
      if bCanSync and bGotWork then
        running_synchronous := true;

      FIncomingItems.Unlock;
      if bGotwork then
      try
        if bCanSync then begin
          try
            //spin := true;
            autospin := false;
            stepcount := 1;
            step := 1;
            itm.Queue := self;
            tm := GetHighResTicker;
{$IFDEF QUEUE_DEBUG}            Debug.Log('Synchronous Execute of '+itm.GetObjectDebug);{$ENDIF}
            itm.Execute;//<----------------------------
            tm2 := GetHighResTicker;
            last_process_time := gettimesince(tm2,tm);
            if keepstats then begin
              rs.AddStat(last_Process_time);
            end;
            if AutoMaintainIdleInterval then begin
              NoWorkRunInterval := greaterof(1, round(rs.PEriodicAverage*0.0002));   //TWO SPOTS
            end;



            step := 0;
            //spin := false;
          finally
            running_synchronous := false;
          end;
          exit;
        end;
      finally
        FWorkingItems.Unlock;

        if itm.AutoDestroy then begin
{$IFDEF QUeUE_DEBUG}Debug.Log('Auto Destroy '+itm.Getobjectdebug);{$ENDIF}
          itm.SignalComplete;
          itm.queue := nil;
          itm.Free;
        end else
          itm.SignalComplete;

        IterationComplete;
        UpdateStatus(false);

      end;
    end;

  end;

  autospin := true;
  //REGULAR ADD
  bWait := false;
  itm.Queue := self;
  FIncomingItems.Lock;
  try
{$IFDEF QUeUE_DEBUG}Debug.Log('adding to incoming queue '+itm.GetObjectDebug);{$ENDIF}
    if estimated_queue_size = 0 then begin
      if assigned(FOnNotEmpty) then
        FOnNotEmpty(self);//!!!!---- under lock!
    end;
    FIncomingItems.add(itm);
    estimated_backlog_size := FIncomingItems.countvolatile;

  //  Debug.ConsoleLog('Queued item #'+inttostr(FIncomingitems.count));
//    OptimizeIncoming(itm);
    if itm.Queue = nil then
      raise Ecritical.Create('catastrophe! .. no queue assigned to '+itm.classname);
    bWait := (FIncomingItems.countvolatile > MaxItemsInQueue) and (MaxItemsInQueue > 0);
  finally
    FIncomingItems.Unlock;
  end;
{$IFDEF EXECUTE_ON_ADD}
  ProcessItem;
  if estimated_queue_size > 0 then
    dec(estimated_queue_size);
{$ENDIF}
  HasWork := true;
  UpdateStatus(false);



  if bWait then begin
    sleeptime := 0;
    repeat
      FIncomingItems.lock;
      try
        bWait := QueueFull;
      finally
        FIncomingItems.Unlock;
      end;
      if bWait then begin
        if sleeptime > 0 then begin
          sleep(sleeptime);//THE REASON WE ALLOW SLEEP HERE
                           //IS TO BACK OFF when the Queue is full.  This allows the
                           //time-critical thread a chance to drain the incoming items
        end;
        WaitForSignal(evNotCongested);
        if sleeptime < 50 then
          inc(sleeptime);

//        exit;
      end;
    until not bWait;

  end;


end;

procedure TAbstractSimpleQueue.AddItemQuick(itm: TQueueItem);
var
  bWait: boolean;
  bGotWork: boolean;
  bCanSync: boolean;
  tm, tm2: ticker;
  sleeptime: ticker;
begin
  rsAdd.BeginTime;
  autospin := true;
  //REGULAR ADD
  bWait := false;
  itm.Queue := self;
  rsAddLock.begintime;
  FIncomingItems.Lock;
  try
    rsAddLock.EndTime;
    rsAddLock.OptionDebug('quick add lock time');
    FIncomingItems.add(itm);
    estimated_backlog_size := FIncomingItems.countvolatile;

    bWait := (FIncomingItems.countvolatile > MaxItemsInQueue) and (MaxItemsInQueue > 0);
  finally
    FIncomingItems.Unlock;
  end;
  HasWork := true;
  rsAddExtras.begintime;
  UpdateStatus(false);

  if bWait then begin
    sleeptime := 0;
    repeat
      FIncomingItems.lock;
      try
        bWait := QueueFull;
      finally
        FIncomingItems.Unlock;
      end;
      if bWait then begin
        if sleeptime > 0 then begin
          sleep(sleeptime);//THE REASON WE ALLOW SLEEP HERE
                           //IS TO BACK OFF when the Queue is full.  This allows the
                           //time-critical thread a chance to drain the incoming items
        end;
        WaitForSignal(evNotCongested);
        if sleeptime < 50 then
          inc(sleeptime);

//        exit;
      end;
    until not bWait;

  end;
  rsAddExtras.EndTime;
  rsAddExtras.optiondebug('add extras time');

  rsAdd.EndTime;
  rsAdd.optionDebug('Quick Add Time: ');


end;

procedure TAbstractSimpleQueue.AfterProcessItem;
begin
  //
end;

procedure TAbstractSimpleQueue.AfterUrgentCopy;
begin
//no implementation required
end;


procedure TAbstractSimpleQueue.BlockIncoming;
begin
  if not FBlockIncoming then begin
    Signal(evNotCongested, false);
    FIncomingItems.lock;
    FBlockIncoming := true;
  end;
end;

procedure TAbstractSimpleQueue.CheckWorkingItems;
begin
{$IFDEF EXTRA_CHECKS}
  for var t:= 0 to FWorkingItems.count-1 do begin
    var w := FWorkingItems[t];
    if w.IsDead then
      raise Ecritical.create('working items contains DEAD '+w.classname);
  end;
{$ENDIF}
end;

function TAbstractSimpleQueue.CollectIncoming(bForce: boolean): boolean;
var
  t,i: ni;
begin
  if not evHold.WaitFor(1000) then begin
    Debug.Log(self, 'Hold signal wait timeout');
    evhold.Signal(true);
  end;
  if bForce or urgent then begin
    FIncomingItems.Lock;
    try
      if FWorkingIndex >= FWorkingItems.countvolatile then begin
        FWorkingItems.clear;
        FWorkingIndex := 0;
      end;
      FWorkingItems.AddList(FIncomingItems);
{$IFDEF REPRIORITIZE}
      FincomingItems.Clear;
      for t:= 0 to FWorkingItems.count-1 do begin
        i := FIncomingItems.Add(FWorkingItems[t]);
        OptimizeIncoming(FWorkingItems[t],i);
      end;
      FWorkingItems.Clear;
      FWorkingItems.AddList(FIncomingItems);
{$ENDIF}
      FIncomingItems.Clear;

      estimated_backlog_size := 0;
      estimated_queue_size := FWorkingItems.countvolatile;
      urgent := false;
      AfterUrgentCopy;
    finally
      FIncomingItems.Unlock;
    end;
    result := FWorkingItems.countvolatile > 0;
  end else begin
{$DEFINE HOLD_IN_INCOMING_LONGER}
{$IFDEF HOLD_IN_INCOMING_LONGER}
    result := false;
{$ELSE}
    result := FIncomingItems.TryLock;
    if result then begin
      FWorkingItems.AddList(FIncomingItems);
      checkworkingItems;
      FincomingItems.Clear;
      FIncomingItems.Unlock;
      result := FWorkingItems.Count>0;

    end;
{$ENDIF}
  end;


  if not result then begin
    if Assigned(OnEmpty) then
      OnEmpty(self);
    if Assigned(FAONEmpty) then
      FAOnEmpty();
  end;

end;

destructor TAbstractSimpleQueue.Destroy;
begin
  rs.free;
  rs := nil;
  rsIdle.free;
  rs := nil;
  rsAdd.free;
  rsAdd := nil;
  rsAddLock.free;
  rsAddLock := nil;
  rsAddExtras.free;
  rsAddExtras := nil;

  inherited;
end;

procedure TAbstractSimpleQueue.Detach;
begin


{$IFDEF TRACK_COMPLETED}
  if FCompletedItems.count > 0 then
    raise ECritical.create('It is bad to destroy TAbstractSimpleQueue while there are items waiting in the CompletedItems list.');

  FCompletedItems.free;
{$ENDIF}

  FWorkingItems.free;
  FIncomingItems.free;
  DCS(FExecuteLock);
  evHold.free;
  evHold := nil;
  evNotCongested.free;
  evNotCongested := nil;
  signal(evQueueIdle, true);
  evQueueIdle.free;
  evQueueIdle := nil;

  inherited;

end;

procedure TAbstractSimpleQueue.DoExecute;
var
  tm1, tm2: ticker;
begin
  inherited;
  tm1 := GetHighResTicker;
  rsIdle.AddStat(GettimeSince(idleTick));
  ProcessItem;
  tm2 := GetHighResTicker;
  if estimated_queue_size > 0 then
    dec(estimated_queue_size);

  last_process_time := GetTImeSince(tm2,tm1);
  if keepstats then
    rs.addstat(last_process_time);



  if AutoMaintainIdleInterval then begin
     NoWorkRunInterval := greaterof(1, round(rs.PeriodicAverage*0.0002))
//     NoWorkRunInterval := 1;//TWO SPOTS!
  end;
  inc(FIterations);
  IterationComplete;
  idleTick := GetTicker;
end;

procedure TAbstractSimpleQueue.DropPending;
var
  i: TQueueItem;
  x: ni;
begin
  Lock;
  try
    while FIncomingItems.countvolatile > 0 do begin
      x := FincomingItems.countvolatile-1;
      i := FIncomingItems[x];
      i.cancelled := true;
      FIncomingItems.Delete(x);
      if i.AutoDestroy then begin
        i.free;
        i := nil;
      end;
    end;

    while FWorkingItems.countvolatile > 0 do begin
      x := FWorkingItems.countvolatile-1;
      i := FWorkingItems[x];
      i.cancelled := true;
      FWorkingItems.Delete(x);
      if i.AutoDestroy then begin
        i.free;
        i := nil;
      end;
    end;

  finally
    Unlock;
  end;
end;

procedure TAbstractSimpleQueue.ExecuteUnlock;
begin
  LCS(FExecuteLock);
end;

function TAbstractSimpleQueue.GetHold: boolean;
begin
  result := not evhold.IsSignaled;
end;

function TAbstractSimpleQueue.GetNextItem: TQueueItem;
begin
  //todo 1: this can be WAY more efficient
  repeat
    CheckWorkingItems;
{$IFDEF FASTER_WORKING_ITEMS}
    if FWorkingIndex >= FworkingItems.count then
      result := nil
    else begin
      result := FWorkingItems[FWorkingIndex];
      inc(FWorkingIndex);
    end;

{$ELSE}
    result := FWorkingItems[0];//default, override me if you want to implement custom ordering
    if result = nil then
      FWorkingItems.delete(0);

{$ENDIF}
  until (result <> nil)
{$IFDEF FASTER_WORKING_ITEMS}
  or (FWorkingIndex >= Fworkingitems.count)
{$endIF}
  or (FWorkingItems.countvolatile = 0);

end;



function TAbstractSimpleQueue.EstimatedSize: ni;
begin
  result := Estimated_queue_size+estimated_backlog_size;
end;

procedure TAbstractSimpleQueue.ExecuteLock;
begin
  ECS(FExecuteLock);
end;

function TAbstractSimpleQueue.IdleBreak: Boolean;
begin
  exit(estimated_backlog_size > 0);
end;

procedure TAbstractSimpleQueue.Init;
begin
  inherited;
  FIncomingItems := TQueueItemList.create;
  FWorkingItems := TQueueItemList.create;
{$IFDEF TRACK_COMPLETED}
  FCompletedItems := TQueueItemList.create;
{$ENDIF}
  ICSSC(FExecuteLock, QUEUE_SPIN);
  Loop := true;
  evQueueIdle := TSignal.create;
  signal(evQueueIdle,true);
  evhold := TSignal.create;
  evNotCongested := TSignal.create;
  KeepStats := true;
  if rs = nil then begin
    rs := TRingStats.create;
    rs.Size := 4096;
  end;

  if rsAdd = nil then begin
    rsAdd := TRingStats.create;
//    rsAdd.Size := 4096;
  end;

  if rsAddLock = nil then begin
    rsAddLock := TRingStats.create;
//    rsAdd.Size := 4096;
  end;

  if rsAddExtras = nil then begin
    rsAddExtras := TRingStats.create;
//    rsAdd.Size := 4096;
  end;


  if rsIdle = nil then begin
    rsIdle := TRingStats.create;
    rsIdle.size := 4096;
  end;


end;

procedure TAbstractSimpleQueue.InitFromPool;
begin
  inherited;
  shutdown := false;
  urgent := false;
  signal(evnotcongested, true);
  Loop := true;


end;

procedure TAbstractSimpleQueue.OnPrepareToStop;
begin
  inherited;
  shutdown := true;
  signal(Self.evQueueIdle,true);
  signal(Self.evHold,true);
  signal(Self.evNotCongested,true);

end;

procedure TAbstractSimpleQueue.OptimizeIncoming;
begin
  //
end;

procedure TAbstractSimpleQueue.ProcessAllSynchronously;
begin
  while (FIncomingItems.countvolatile > 0) or (FWorkingItems.countvolatile > 0) do begin
    ProcessItem;
  end;
end;


function TAbstractSimpleQueue.QueueFull: boolean;
begin
  if not FincomingItems.trylock then
    exit(true);
  try
    result := (FIncomingItems.countvolatile >= MaxItemsInQueue) and (MaxItemsInQueue > 0);
  finally
    FincomingItems.Unlock;
  end;
end;

procedure TSimpleQueue.ProcessItem;
var
  itm: TQueueItem;
begin

//  Debug.ConsoleLog('Process');
  if ((FWorkingItems.Volatilecount = 0) or (gettimeSince(tmLastCollection) > 100))
  and FIncomingItems.TryLock then
  try
    CollectIncoming(FWorkingItems.Volatilecount=0);
    tmLastCollection := getticker;
    HasWork := (FWorkingItems.countvolatile > 0) or (FIncomingItems.countvolatile > 0);//NOTE! IMPORTANT!  This should be the ONLY place where HasWork is evaluated
    if not HasWork then
      Signal(evQueueIdle);

    //if we set a limit on the number of items we can queue then prevent
    //other threads from getting a lock on the incoming list

    if (MaxItemsInQueue > 0) and (FWorkingItems.countvolatile >= MaxItemsInQueue) then begin
      BlockIncoming;
    end else begin
      UnBlockIncoming;
    end;
  finally
    FIncomingItems.Unlock;
  end;
  UpdateStatus(false);

  if (haswork) then begin
    itm := nil;

    estimated_queue_size := FWorkingitems.countvolatile;

    if FWorkingItems.countvolatile > 0 then  //volatile read of count, could be zero, but shouldn't decrement
      itm := GEtNextItem;

    //if (FIterations mod 100) = 0 then
//    if GetTimeSince(tmLastStatusUpdate) > 100 then
      UpdateStatus(false);


    if itm = nil then
      no_workable_items := true
    else
    try
      ExecuteLock;
      try
      //if (FIterations mod 100) = 0 then
        UpdateStatus(false);


        //executing the item will signal it
//        status := itm.ClassName;
{$IFDEF EXTRA_CHECKS}
        if itm.IsDead then
          raise ECritical.create('trying to execute a '+itm.classname+' that is DEAD');
        if itm.Queue = nil then begin
          raise Ecritical.Create('catastrophe! '+itm.classname+' Has no queue!'+self.Status );
        end;
{$ENDIF}
{$IFDEF QUEUE_DEBUG}Debug.Log('execute queue item '+itm.GetObjectDebug);{$ENDIF}
        if EnableItemDebug then
          Debug.Log(self.name+' Execute Item: '+itm.DebugString);
        FWorkingItems.Remove(itm);
        try
          itm.Execute;
        except
          on e: Exception do begin
            debug.log('Exception executing Queue Item '+itm.classname+' '+e.message);
          end;
        end;
        if enableitemdebug then
          Debug.Log(self.name+' Finish Item: '+itm.DebugString);

        dec(estimated_queue_size);
        UpdateStatus(false);

      finally
        ExecuteUnlock;
      end;
    finally
      if itm.AutoDestroy then begin
{$IFDEF QUeUE_DEBUG}Debug.Log('autodestroy2 '+itm.GetObjectDebug);{$ENDIF}
        itm.queue := nil;
        itm.free;
      end
      else begin
{$IFDEF TRACK_COMPLETED}
        FCOmpletedItems.lock;
        FCompletedItems.add(itm);
        FCompletedItems.Unlock;
{$ENDIF}
        if not itm.wasexecuted then
          raise Ecritical.create('wtf');
        itm.SignalComplete;
      end;
    end;
  end;
end;

procedure TAbstractSimpleQueue.RemoveCompletedItem(itm: TQueueItem);
begin
{$IFDEF TRACK_COMPLETED}
  FCompletedItems.Lock;
  FCompletedItems.Remove(itm);
  FCompletedItems.unlock;
{$ENDIF}
end;

procedure TAbstractSimpleQueue.SelfAdd(qi: TQueueItem);
  //adds directly to working items (assumes underlock)
  //intended for queue items that want to queue other queue items.
begin
  FWorkingItems.Lock;
  try
    FWorkingItems.Add(qi);
    qi.Queue := self;
    inc(estimated_queue_size);
  finally
    FWorkingItems.Unlock;
  end;



end;

procedure TAbstractSimpleQueue.SetHold(const Value: boolean);
begin
  evHold.Signal(not value);
end;

procedure TAbstractSimpleQueue.SetStartingState;
begin
  inherited;
  betterpriority := bpHighest;
  evQueueIdle := TSignal.create;
  Hold := false;
  AutoSpin := true;

end;

function TAbstractSimpleQueue.Stop(bySelf: boolean=false): boolean;
begin
  shutdown := true;
  result := inherited;

end;

function TAbstractSimpleQueue.TryExecuteLock: boolean;
begin
  result := TECS(FExecuteLock);
end;

procedure TAbstractSimpleQueue.UnBlockIncoming;
begin
  if FBlockIncoming then begin
    Signal(evNotCongested, true);
    FIncomingItems.unlock;
    FBlockIncoming := false;
  end;
end;

procedure TAbstractSimpleQueue.UpdateStatus(bForce: boolean);
begin

  Spin := (estimated_backlog_size+estimated_queue_size) > 0;
  if bForce or (GetTimeSInce(status_time) > 250) then begin
    Status := 'bcklg: '+inttostr(estimated_backlog_size)+' wrk:'+inttostr(estimated_queue_size)+' avg(us):'+round(rs.PeriodicAverage/10).ToString+' nwr:'+noworkruninterval.tostring+' sf:'+sidefetches.tostring+' hit:'+hits.tostring+' miss:'+misses.tostring;
    Status_time := getticker;
  end;
end;

procedure TAbstractSimpleQueue.WaitForAll;
begin
  while HasWork do begin
    WaitForSignal(evQueueIdle,100);
  end;
end;

procedure TAbstractSimpleQueue.WaitForFinish;
begin
  inherited;
//  DropPending;
  while not IsFinished do
    sleep(1);
  ProcessAllSynchronously;
end;

{ TQueueItem }

constructor TQueueItem.Create;
begin
  FWaitSignal := TSignal.create;
  inherited;

end;

function TQueueItem.DebugString: string;
begin
  result := classname;
end;

destructor TQueueItem.Destroy;
begin
  if FQueue <> nil then
    raise Ecritical.create('cannot destroy a '+classname+' while it is assigned to a queue.');
  if not cancelled then begin
    if not wasexecuted then
      raise Ecritical.create(getobjectdebug+' was never executed!');
  end;
  FWaitSignal.free;
  inherited;
end;

procedure TQueueItem.Detach;
begin
  if FQueue <> nil then begin
    FQueue.RemoveCompletedItem(self);
    FQueue := nil;
  end;

  inherited;
end;

procedure TQueueItem.DoExecute;
begin
  //
end;

procedure TQueueItem.Execute;
begin
  wasexecuted := true;
//  self.queue.status := debugstring;
  DoExecute;
  if assigned(onfinish_anon) then
    onFinish_anon(self);

end;

function TQueueItem.GEtWait: boolean;
begin
  result := IsSignaled(FWaitSignal);

end;

procedure TQueueItem.Init;
begin
  inherited;

end;

function TQueueItem.IsComplete: boolean;
begin
  result := GEtWait;
end;

procedure TQueueItem.SignalComplete;
begin
  Signal(FWaitSignal, true);
end;

function TQueueItem.WAitFor(iTimeout: ni = -1): boolean;
begin
  result := WaitForSignal(FWaitSignal, iTimeout);
end;

{ TFakeCommand }

function TFakeCommand.GEtStatus: string;
begin
  //
end;

procedure TFakeCommand.InitExpense;
begin
  //this is a stub that is not used.  here to maintain interface compatability with TCommand
end;

procedure TFakeCommand.SetStatus(Value: string);
begin
  //
end;

procedure TFakeCommand.Start(queue: TAbstractSimpleQueue);
begin
  queue.AddItem(self);
end;

{ TMultiQueue }

procedure TMultiQueue.AddItem(itm: TQueueItem);
begin
  GetShortestQueue.AddItem(itm);
end;

constructor TMultiQueue.Create;
var
  startcount: ni;
begin
  inherited;
  RoundRobin := true;
  evEmptyAvailable := TSignal.create;
  FList := TBetterList<TSimpleQueue>.create;
  startcount := lesserof(MQ_START_COUNT,GetEnabledCPUCount);
  while FList.Count < startcount do begin
    FList.Add(TPM.Needthread<TSimpleQueue>(nil));
    FList[FList.count-1].Name := 'MQ'+inttostr(FList.count-1);
    FList[FList.count-1].OnEmpty := self.QueueOnEmpty;
    FList[FList.count-1].BetterPriority := bpHighest;
    FList[FList.count-1].Loop := true;
    FList[FList.count-1].BeginStart;

  end;
end;

procedure TMultiQueue.CheckGrowQueueThreads;
begin
  if growfinished then exit;
  Lock;
  try
    if FList.Count < GEtnumberOfLogicalProcessors then begin
      FList.Add(TPM.Needthread<TSimpleQueue>(nil));
      FList[FList.count-1].Name := 'MQ'+inttostr(FList.count-1);
      FList[FList.count-1].OnEmpty := self.QueueOnEmpty;
      FList[FList.count-1].BetterPriority := bpHighest;
      FList[FList.count-1].Loop := true;
      FList[FList.count-1].BeginStart;
      growfinished := FList.count >= GEtnumberOfLogicalProcessors;
    end else
      growfinished := true;


  finally
    Unlock;
  end;

end;

destructor TMultiQueue.Destroy;
var
  q: TSimpleQueue;
  t: ni;
begin
  for t:= 0 to FList.count-1 do begin
    Debug.Log('Freeing MultiQueue.  Subqueues='+inttostr(Flist.count));
    q := FList[t];
    q.EndStart;
    Debug.Log('Freeing MultiQueue.  WAitForall');
    q.WaitForAll;
    Debug.Log('Freeing MultiQueue.  Stop');
    q.BeginStop;
  end;
  while FList.Count > 0 do begin
    q := FList[FList.count-1];
    q.EndStop(false);
    Debug.Log('Freeing MultiQueue.  WaitForFinish');
    q.WaitForFinish;
    FList.delete(FList.count-1);
    Debug.Log('Freeing MultiQueue.  No Need');
    TPM.NoNeedthread(q);
//    q.Free;
    q := nil;
  end;

  evEmptyAvailable.free;
  evEmptyAvailable := nil;
  FList.free;
  inherited;
end;

function TMultiQueue.EstimatedSize: ni;
begin
  result := estimated_backlog_size;
end;

function TMultiQueue.estimated_queue_size: ni;
var
  t: ni;
begin
  result := 0;
  for t:= 0 to FList.count-1 do begin
    result := result + FList[t].estimated_queue_size;
  end;

end;

function TMultiQueue.estimated_backlog_size: ni;
var
  t: ni;
begin
  result := 0;
  for t:= 0 to FList.count-1 do begin
    result := result + FList[t].estimated_backlog_size;
  end;

end;

function TMultiQueue.GetShortestQueue: TSimpleQueue;
var
  t: ni;
begin
  if RoundRobin then begin
    Lock;
    try
      if not growfinished then
        if FList.count = 0 then
          CheckGrowQueueThreads;
      inc(rridx);
      if rridx >= Flist.count then
        rridx := 0;

      result := FList[rridx];
    finally
      Unlock;
    end;

  end else begin
    //if we've grown to the number of CPUs available, then we can use a simplified execution path
    if growfinished then begin
      result := FList[0];
      for t:= 1 to FList.count-1 do begin
        if FList[t].estimated_queue_size < result.estimated_queue_size then begin
          result := FList[t];
        end;
      end;
    end else begin
      Lock;
      try
        result := FList[0];
        if FList.count = 0 then
          CheckGrowQueueThreads;
        for t:= 1 to FList.count-1 do begin
          if FList[t].estimated_queue_size < result.estimated_queue_size then begin
            result := FList[t];
          end;
        end;
      finally
        Unlock;
      end;
    end;
  end;

  //if the queue has items, then it might be time to grow the queue (up to number of CPUs)
  if not growfinished then
    if result.estimated_queue_size > 0 then
      CheckGrowQueueThreads;

end;


procedure TMultiQueue.QueueOnEmpty(sender: TObject);
begin
  evEmptyAvailable.Signal(true);

end;

procedure TMultiQueue.SetMaxItemsInQueue(const Value: ni);
var
  t: ni;
begin
  FMaxItemsInQueue := Value;
  Lock;
  try
    for t:= 0 to FList.count-1 do begin
      fList[t].MaxItemsInQueue := value;
    end;
  finally
    unlock;
  end;

end;

procedure TMultiQueue.Start;
begin
  //
end;

procedure TMultiQueue.WaitForAllQueues;
var
  t: ni;
begin
  Lock;
  try
    for t:= 0 to FList.count-1 do begin
      FList[t].WaitForAll;
    end;
  finally
    Unlock;
  end;

end;

function TMultiQueue.WaitForEmptyQueue(iTimeout: ni): TSimpleQueue;
begin
  result := GetShortestQueue;

  if result.estimated_queue_size = 0 then
    exit;

  if not WaitForSignal(evEmptyAvailable, iTimeout) then
    exit(nil);

  result := GetShortestQueue;

end;

{ TAnonymousQueueItem }

procedure TAnonymousQueueItem.DoExecute;
begin
  inherited;
  AnonMethod();
end;

procedure TAnonymousQueueItem.Init;
begin
  inherited;

end;



function TSimpleQueue.QueueAnonymous(bAutoDestroy: boolean; proc: TAnonymousQueueProc): TAnonymousQueueItem;
var
  itm: TAnonymousQueueItem;
begin
  itm := TAnonymousQueueItem.Create;
  itm.AnonMethod := proc;
  itm.AutoDestroy := bAutoDestroy;
  Self.AddItem(itm);
  result := itm;
end;

{ TIndirectlyLinkableQueueItem }

procedure TIndirectlyLinkableQueueItem.AddLinkage(
  link: TLinkage<TIndirectlyLinkableQueueItem>; list: TObject);
begin
//
  setlength(indirectlinkage, length(indirectlinkage)+1);
  indirectlinkage[high(indirectlinkage)] := link;

end;

function TIndirectlyLinkableQueueItem.GetLinkageFor(
  obj: TObject): TLinkage<TIndirectlyLinkableQueueItem>;
var
  t: ni;
begin
  result := nil;
  for t:= 0 to high(indirectlinkage) do begin
    if indirectlinkage[t].obj = obj then
      exit(indirectlinkage[t]);
  end;
//
end;

procedure TIndirectlyLinkableQueueItem.RemoveLinkage(list: TObject);
var
  idx: ni;
  t,u: ni;
begin
  idx := -1;
  for t:= 0 to high(indirectlinkage) do begin
    if indirectlinkage[t].obj = list then begin
      for u := t to high(indirectlinkage)-1 do begin
        indirectlinkage[u] := indirectlinkage[u+1];
      end;
      setlength(indirectlinkage, length(indirectlinkage)-1);
    end;

  end;

//
end;

{ TqiAddQueueItem }

procedure TqiAddQueueItem.DoExecute;
begin
  inherited;
  q.AddItem(qi);
end;

end.
