unit Rights;

interface

uses RequestInfo, MTDTInterface, Dataobject, sysutils, windows, rightsClasses;

function UserHasRight(rqInfo: TRequestInfo; sRight: string): boolean;
function CurrentUserHasRight(rqInfo: TRequestInfo; sRight: string): boolean;

function RightsDispatch(rqInfo: TRequestInfo; sRight: string; out right: PRight): boolean;
function RoleHasRight(rqInfo: TRequestInfo; sRight: string; iRoleID: integer): boolean;




implementation


//------------------------------------------------------------------------------
function UserHasRight(rqInfo: TRequestInfo; sRight: string): boolean;
begin
  raise Exception.create('Unimplemented');
end;
//------------------------------------------------------------------------------
function RoleHasRight(rqInfo: TRequestInfo; sRight: string; iRoleID: integer): boolean;
var
  doRight: TDataObject;
  right: PRight;
begin
  doRight := LazyQuery(rqInfo, 'SELECT * from Role where roleid='+inttostr(iRoleID), false);


  if RightsDispatch(rqINfo, sRight, right) then begin
    if ((doRight.fieldbyindex[2+0].AsVariant and right.f1) = right.f1)
    and((doRight.fieldbyindex[2+1].AsVariant and right.f2) = right.f2)
    and((doRight.fieldbyindex[2+2].AsVariant and right.f3) = right.f3)
    and((doRight.fieldbyindex[2+3].AsVariant and right.f4) = right.f4)
    and((doRight.fieldbyindex[2+4].AsVariant and right.f5) = right.f5)
    and((doRight.fieldbyindex[2+5].AsVariant and right.f6) = right.f6)
    and((doRight.fieldbyindex[2+6].AsVariant and right.f7) = right.f7)
    and((doRight.fieldbyindex[2+7].AsVariant and right.f8) = right.f8)
    then begin
      result := true;
    end else begin
      result := false
    end;
  end else begin
    result := false;
  end;

end;

function CurrentUserHasRight(rqInfo: TRequestInfo; sRight: string): boolean;
var
  doRight: TDataObject;
  right: PRight;
  iRoleID: integer;
begin
//  doRight := LazyQuery(rqInfo, 'SELECT * Role where roleid='+inttostr(iRoleID), false);
  var sess := QuickSession(rQInfo);
  if sess = nil then
    exit(false);
  iRoleID := sess.assoc['user']['roleid'].AsVariant;
  doRight := LazyQueryMap(rqInfo, 'SELECT * from Role where roleid='+inttostr(iRoleID),'TdoRole',  iroleID);

  if RightsDispatch(rqINfo, sRight, right) then begin
    if ((doRight.fieldbyindex[1+0].AsVariant and right.f1) = right.f1)
    and((doRight.fieldbyindex[1+1].AsVariant and right.f2) = right.f2)
    and((doRight.fieldbyindex[1+2].AsVariant and right.f3) = right.f3)
    and((doRight.fieldbyindex[1+3].AsVariant and right.f4) = right.f4)
    and((doRight.fieldbyindex[1+4].AsVariant and right.f5) = right.f5)
    and((doRight.fieldbyindex[1+5].AsVariant and right.f6) = right.f6)
    and((doRight.fieldbyindex[1+6].AsVariant and right.f7) = right.f7)
    and((doRight.fieldbyindex[1+7].AsVariant and right.f8) = right.f8)
    then begin
      result := true;
    end else begin
      result := false
    end;
  end else begin
    result := false;
  end;

end;

function RightsDispatch(rqInfo: TRequestInfo; sRight: string; out right: PRight): boolean;
begin
  right := FindRight(sRight);
  result := right <> nil;


  if not result then
    raise Exception.create('Right not defined: '+sRight);

  //windows.beep(100,10);

end;







end.



