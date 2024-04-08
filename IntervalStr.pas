unit IntervalStr;

interface

uses
  System.Types, System.SysUtils, System.Classes, System.Generics.Collections, System.Generics.Defaults;

type
  TIntervalUnits = class(TPersistent)
  private type
    TUnit = record
      Name: string;
      Value: UInt64;
    end;
  private
    FNames: TDictionary<string, UInt64>;
    FEncodingOrder: TList<TUnit>;
  private
    class var FDefault: TIntervalUnits;
  protected
    class constructor Create;
    class destructor Destroy;
    property  Names: TDictionary<string, UInt64> read FNames;
    property  EncodingOrder: TList<TUnit> read FEncodingOrder;
  public
    class property Default: TIntervalUnits read FDefault;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const Name: string; const Value: UInt64; UseToEncode: Boolean = False);
    procedure Remove(const Name: string);
  end;


function IntervalStrToMSec(const S: string; const Units: TIntervalUnits): UInt64; overload; inline;
function IntervalStrToMSec(const S: string): UInt64; overload; inline;
function TryIntervalStrToMSec(const S: string; out Interval: UInt64; const Units: TIntervalUnits): Boolean; overload;
function TryIntervalStrToMSec(const S: string; out Interval: UInt64): Boolean; overload; inline;

function MSecToIntervalStr(Value: UInt64; const Units: TIntervalUnits): string; overload;
function MSecToIntervalStr(Value: UInt64): string; overload; inline;

resourcestring
  SInvalidIntervalStr = 'Invalid interval string';

implementation

function MSecToIntervalStr(Value: UInt64): string;
begin
  Result := MSecToIntervalStr(Value, TIntervalUnits.Default);
end;

function MSecToIntervalStr(Value: UInt64; const Units: TIntervalUnits): string;
var
  Parts: TArray<string>;
begin
  if Value = 0 then
    Exit('0')
  else if Units.EncodingOrder.Count = 0 then
    Exit(UIntToStr(Value));

  SetLength(Parts, Units.EncodingOrder.Count + 1);
  var J := 0;
  for var I := Units.EncodingOrder.Count - 1 downto 0 do
  begin
    var Item := Units.EncodingOrder[I];
    var Part := Value div Item.Value;

    if Part <> 0 then
    begin
      Parts[J] := UIntToStr(Part) + Item.Name;
      Inc(J);
    end;

    Value := Value mod Item.Value;
  end;

  if Value <> 0 then
  begin
    Parts[J] := UIntToStr(Value);
    Inc(J);
  end;
  SetLength(Parts, J);

  Result := string.Join(' ', Parts);
end;

function IntervalStrToMSec(const S: string; const Units: TIntervalUnits): UInt64;
begin
  if not TryIntervalStrToMSec(S, Result, Units) then
    raise EConvertError.CreateRes(@SInvalidIntervalStr);
end;

function IntervalStrToMSec(const S: string): UInt64;
begin
  if not TryIntervalStrToMSec(S, Result) then
    raise EConvertError.CreateRes(@SInvalidIntervalStr);
end;

function TryIntervalStrToMSec(const S: string; out Interval: UInt64): Boolean;
begin
  Result := TryIntervalStrToMSec(S, Interval, TIntervalUnits.Default);
end;

function TryIntervalStrToMSec(const S: string; out Interval: UInt64; const Units: TIntervalUnits): Boolean;
var
  UnitValue, Value: UInt64;
  B, I, L: Integer;
begin
  Result := False;

  L := Length(S);
  if L = 0 then
    Exit;

  Interval := 0;

  I := 1;
  while I <= L do
  begin
    case S[I] of
      #0..#32:
        Inc(I); //Skip spaces

      '0'..'9':
        begin
          Value := 0;
          while (I <= L) and CharInSet(S[I], ['0'..'9']) do
          begin
            Value := Value * 10 + Ord(S[I]) - Ord('0');
            Inc(I);
          end;

          while (I <= L) and CharInSet(S[I], [#0..#32]) do
            Inc(I);

          B := I;
          while (I <= L) and CharInSet(S[I], ['a'..'z', 'A'..'Z']) do
            Inc(I);

          if B = I then // No units specified, must be last
          begin
            while I <= L do
              if S[I] > #32 then
                Exit(False);
            Interval := Interval + Value;
            Exit(True);
          end;

          if Units.Names.TryGetValue(Copy(S, B, I - B), UnitValue) then
            Interval := Interval + Value * UnitValue
          else
            Exit(False);

          Result := True;
        end;
    else
      Exit(False);
    end;
  end;
end;

{ TIntervalUnits }

constructor TIntervalUnits.Create;
begin
  inherited Create;
  FNames := TDictionary<string, UInt64>.Create(TIStringComparer.Ordinal);
  FEncodingOrder := TList<TUnit>.Create;
end;

destructor TIntervalUnits.Destroy;
begin
  FreeAndNil(FNames);
  FreeAndNil(FEncodingOrder);
  inherited;
end;

class constructor TIntervalUnits.Create;
begin
  FDefault := TIntervalUnits.Create;

  FDefault.Add('d', MSecsPerDay, True);
  FDefault.Add('day', MSecsPerDay);
  FDefault.Add('days', MSecsPerDay);

  FDefault.Add('h', SecsPerHour * MSecsPerSec, True);
  FDefault.Add('hrs', SecsPerHour * MSecsPerSec);
  FDefault.Add('hour', SecsPerHour * MSecsPerSec);
  FDefault.Add('hours', SecsPerHour * MSecsPerSec);

  FDefault.Add('m', SecsPerMin * MSecsPerSec, True);
  FDefault.Add('min', SecsPerMin * MSecsPerSec);
  FDefault.Add('mins', SecsPerMin * MSecsPerSec);
  FDefault.Add('minute', SecsPerMin * MSecsPerSec);
  FDefault.Add('minutes', SecsPerMin * MSecsPerSec);

  FDefault.Add('s', MSecsPerSec, True);
  FDefault.Add('sec', MSecsPerSec);
  FDefault.Add('secs', MSecsPerSec);
  FDefault.Add('second', MSecsPerSec);
  FDefault.Add('seconds', MSecsPerSec);
end;

class destructor TIntervalUnits.Destroy;
begin
  FreeAndNil(FDefault);
end;

procedure TIntervalUnits.Add(const Name: string; const Value: UInt64; UseToEncode: Boolean);
begin
  Names.AddOrSetValue(Name, Value);

  if UseToEncode then
  begin
    var Item: TUnit;
    Item.Name := Name;
    Item.Value := Value;

    for var I := 0 to EncodingOrder.Count - 1 do
      if EncodingOrder[I].Value = Value then
      begin
        EncodingOrder[I] := Item;
        Exit;
      end
      else if EncodingOrder[I].Value > Value then
      begin
        EncodingOrder.Insert(I, Item);
        Exit;
      end;

    EncodingOrder.Add(Item);
  end;
end;

procedure TIntervalUnits.Remove(const Name: string);
begin
  Names.Remove(Name);

  for var I := 0 to EncodingOrder.Count - 1 do
    if EncodingOrder[I].Name = Name then
    begin
      EncodingOrder.Delete(I);
      Exit;
    end;
end;

end.
