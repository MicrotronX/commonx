unit RDTPDMXExternalControlClient;
{GEN}
{TYPE CLIENT}
{CLASS TDMXExternalControlClient}
{IMPLIB RDTPDMXExternalControlClientImplib}
{TEMPLATE RDTP_gen_client_template.pas}
{RQFILE RDTPDMXExternalControlRQs.txt}
{END}
interface


uses
  packetabstract, betterobject, systemx, genericRDTPClient, variants, packethelpers, debug, typex, exceptions;



type
  TDMXExternalControlClient = class(TGenericRDTPClient)
  public
    procedure Init;override;
    destructor Destroy;override;

    


    function DispatchCallback: boolean;override;

  end;

procedure LocalDebug(s: string; sFilter: string = '');


implementation

uses
  sysutils;

procedure LocalDebug(s: string; sFilter: string = '');
begin
  Debug.Log(nil, s, sFilter);
end;



{ TDMXExternalControlClient }


destructor TDMXExternalControlClient.destroy;
begin

  inherited;
end;





function TDMXExternalControlClient.DispatchCallback: boolean;
var
  iRQ: integer;
begin

  result := false;

  iRQ := callback.request.data[0];
  callback.request.seqseek(3);
  case iRQ of
    0: begin
        //beeper.Beep(100,100);
        result := true;
       end;
  
  end;

  if not result then
    result := Inherited DispatchCallback;
end;



procedure TDMXExternalControlClient.Init;
begin
  inherited;
  ServiceName := '';
end;

end.


