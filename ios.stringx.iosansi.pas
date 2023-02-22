unit ios.stringx.iosansi;
{$I 'DelphiDefs.inc'}

interface

uses
  sysutils, classes, commonconstants;

type
  TSplitSet = array of string;

  Tiosansichar = packed record
  private
    b: byte;
    class function AnsiFromChar(c: char): byte;static;
    class function CharFromAnsi(b: byte): char;static;
  public
    procedure FromChar(c: char);
    procedure FromOrd(b: byte);
    function ToChar: char;
    function ToOrd: byte;
    class operator Implicit(const s: Tiosansichar): string;
    class operator Implicit(const s: Tiosansichar): char;
    class operator Implicit(const s: Tiosansichar): byte;
    class operator Implicit(const s: Tiosansichar): pointer;
    class operator Implicit(const c: char): TiosAnsiChar;
    class operator Implicit(const b: byte): TiosAnsiChar;
    class operator NotEqual(a,b: TiosAnsiChar): boolean;
    class operator Equal(a,b: TiosAnsiChar): boolean;
  end;

  Tiosbytestring = record
  private
    Fbytes: TBytes;
    function GetChar(idx: nativeint): char;
    procedure SetChar(idx: nativeint; const Value: char);
    function GetAddrOf(idx: nativeint): pbyte;
    function getbyte(idx: nativeint): byte;
    procedure setbyte(idx: nativeint; const Value: byte);
  public
    property chars[idx: nativeint]: char read GetChar write SetChar;
    property bytes[idx: nativeint]: byte read getbyte write setbyte;
    property addrof[idx: nativeint]: pbyte read GetAddrOf;
    class operator Implicit(const s: TIOSByteString): string;
    class operator Implicit(const s: string): TIOSByteString;
    class operator Add(const s1,s2: TIOSByteString): TIOSByteSTring;
    class operator Add(const s1: string; const s2: TIOSByteString): TIOSByteSTring;
    class operator Add(const s1: TIOSByteString; const s2: string): TIOSByteSTring;
    procedure FromString(s: string);
    function ToString: string;
    procedure SetLength(i: nativeint);
  end;
  TIOSAnsiString = TIOSByteString;
{$IFDEF NEED_FAKE_ANSISTRING}
  ansichar = TIOSAnsiChar;
  ansistring = TIOSByteString;
  utf8string = TIOSByteString;
  widestring = string;
  PAnsiChar = PByte;
{$ENDIF}

function StrPasEx(pc: PAnsiChar): string;

function ordEx(ac: Tiosansichar): nativeint;overload;
{$IFNDEF NEED_FAKE_ANSISTRING}
function ordEx(ac: ansichar): nativeint;overload;inline;
{$ENDIF}

implementation

uses typex;


function StrPasEx(pc: PAnsiChar): string;
begin
  {$IFDEF NEED_FAKE_ANSISTRING}
  result := '';
  while true do begin
    var ordy := pc^;
    if ordy = 0 then
      exit;
    result := result + chr(ordy);
    inc(pc);
  end;
  {$ELSE}
  result := string(StrPas(pc));
  {$ENDIF}
end;

function ordEx(ac: Tiosansichar): nativeint;
begin
  result := ac.ToOrd;
end;

{$IFNDEF NEED_FAKE_ANSISTRING}
function ordEx(ac: ansichar): nativeint;overload;inline;
begin
  result := ord(ac);
end;
{$ENDIF}


{ iosbytestring }

class operator Tiosbytestring.Add(const s1: string;
const s2: TIOSByteString): TIOSByteSTring;
var
  ss2,ss3: string;
begin
  ss2 := s2.ToString;
  ss3 := s1+ss2;
  result.FromString(ss3);

end;

class operator Tiosbytestring.Add(const s1: TIOSByteString;
const  s2: string): TIOSByteSTring;
var
  ss1,ss3: string;
begin
  ss1 := s1.ToString;
  ss3 := ss1+s2;
  result.FromString(ss3);
end;




procedure Tiosbytestring.FromString(s: string);
begin
  Fbytes := TEncoding.ANSI.GetBytes(s);

end;

function Tiosbytestring.GetAddrOf(idx: nativeint): pbyte;
begin
  result := @Fbytes[idx];
end;

function Tiosbytestring.getbyte(idx: nativeint): byte;
begin
  result := Fbytes[idx-strz];
end;

function Tiosbytestring.GetChar(idx: nativeint): char;
begin
  result := Tiosansichar.CharFromAnsi(Fbytes[idx-strzero]);
end;

class operator Tiosbytestring.Implicit(const s: TIOSByteString): string;
begin
  result := s.ToString;

end;

class operator Tiosbytestring.Implicit(const s: string): TIOSByteString;
begin
  result.FromString(s);
end;

procedure Tiosbytestring.setbyte(idx: nativeint; const Value: byte);
begin
  Fbytes[idx-strzero] := value;
end;

class operator Tiosbytestring.Add(const s1,
  s2: TIOSByteString): TIOSByteSTring;
var
  ss1,ss2,ss3: string;
begin
  ss1 := s1.ToString;
  ss2 := s2.ToString;
  ss3 := ss1+ss2;
  result.FromString(ss3);

end;

procedure Tiosbytestring.SetChar(idx: nativeint; const Value: char);
begin
  Fbytes[idx-strzero] := Tiosansichar.AnsiFromChar(value);
end;

procedure Tiosbytestring.SetLength(i: nativeint);
begin
  system.setlength(Fbytes,i);
end;

function Tiosbytestring.ToString: string;
begin
  result := TEncoding.ANSI.GetString(Fbytes);
end;

{ Tiosansichar }


class function Tiosansichar.AnsiFromChar(c: char): byte;
var
  s: string;
  te: TEncoding;
  b: TBytes;
begin
  s := c;

  b := TEncoding.ANSI.GetBytes(c);
  result := b[0];


end;


class function Tiosansichar.CharFromAnsi(b: byte): char;
var
  s: string;
  bytes: TBytes;
begin
  system.setlength(bytes, 1);
  bytes[0] := b;
  s := TEncoding.ANSI.GetString(bytes, 0, 1);
  result := s[low(s)];
end;

class operator Tiosansichar.Equal(a, b: TiosAnsiChar): boolean;
begin
  result := a.b=b.b;
end;

procedure Tiosansichar.FromChar(c: char);
begin
  self.b := AnsiFromChar(c);
end;

procedure Tiosansichar.FromOrd(b: byte);
begin
  self.b := b;
end;

class operator Tiosansichar.Implicit(const c: char): TiosAnsiChar;
begin
  result.b := Tiosansichar.AnsiFromChar(c);
end;

class operator Tiosansichar.Implicit(const s: Tiosansichar): char;
begin
  result := s.ToChar;
end;

class operator Tiosansichar.Implicit(const s: Tiosansichar): string;
begin
  result := s.ToChar;
end;

class operator Tiosansichar.Implicit(const s: Tiosansichar): pointer;
begin
  result := @s.b;
end;

class operator Tiosansichar.Implicit(const s: Tiosansichar): byte;
begin
  result := s.b;
end;

function Tiosansichar.ToChar: char;
begin
  result := CharFromAnsi(b);
end;

function Tiosansichar.ToOrd: byte;
begin
  result := b;
end;

class operator Tiosansichar.Implicit(const b: byte): TiosAnsiChar;
begin
  result := CharFromAnsi(b);
end;

class operator Tiosansichar.NotEqual(a, b: TiosAnsiChar): boolean;
begin
  result := a.b <> b.b;
end;

end.
