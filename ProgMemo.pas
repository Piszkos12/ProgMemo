unit ProgMemo;

interface

uses Classes, StdCtrls, Messages, Controls, StrUtils, SysUtils;

type
  TProgMemoMode = (pmASCII, pmBitByte, pmHEXByte);

type
  TProgMemo = class(TCustomMemo)
  private
    FBuffer: Ansistring;
    FMode: TProgMemoMode;
    FUsePipes: Boolean;
    FPipeChar: AnsiChar;
    Procedure Change; override;
    Procedure DecodeContent;
    Procedure EncodeContent;
    Procedure SetMode(const AMode: TProgMemoMode);
    Procedure SetUsePipes(const AUsePipes: Boolean);
    Procedure SetPipeChar(const APipeChar: AnsiChar);
    Function DecodeFromASCII: Ansistring;
    Function DecodeFromBits: Ansistring;
    Function DecodeFromHEX: Ansistring;
    Function EncodeToASCII: Ansistring;
    Function EncodeToBits: Ansistring;
    Function EncodeToHEX: Ansistring;
  public
    Procedure KeyPress(var Key: Char); override;
    Property Mode: TProgMemoMode read FMode write SetMode;
    Property UsePipes: Boolean read FUsePipes write SetUsePipes;
    Property PipeChar: AnsiChar read FPipeChar write SetPipeChar;
    constructor Create(aOwner: TComponent);
  end;

procedure Register;

implementation

Function TProgMemo.DecodeFromASCII: Ansistring;
begin
  Result := Text;
end;

Function TProgMemo.EncodeToASCII: Ansistring;
begin
  Result := FBuffer;
end;

Function TProgMemo.DecodeFromBits: Ansistring;
var
  bit: Byte;
  value: Byte;
  i: Integer;
begin
  Result := '';
  bit := 0;
  value := 0;
  for i := 1 to Length(Text) do
  begin
    inc(bit);
    if Text[i] = '1' then
      case bit of
        1:
          value := value + 128;
        2:
          value := value + 64;
        3:
          value := value + 32;
        4:
          value := value + 16;
        5:
          value := value + 8;
        6:
          value := value + 4;
        7:
          value := value + 2;
        8:
          value := value + 1;
      end;
    if bit = 8 then
    begin
      Result := Result + Char(value);
      value := 0;
      if not FUsePipes then
        bit := 0;
    end;
    if bit = 9 then
      bit := 0;
  end;
end;

Function TProgMemo.EncodeToBits: Ansistring;
var
  value: Byte;
  i: Integer;
  buf: Ansistring;
begin
  Result := '';
  for i := 1 to Length(FBuffer) do
  begin
    buf := '00000000';
    value := Ord(FBuffer[i]);
    if value and 128 = 128 then
      buf[1] := '1';
    if value and 64 = 64 then
      buf[2] := '1';
    if value and 32 = 32 then
      buf[3] := '1';
    if value and 16 = 16 then
      buf[4] := '1';
    if value and 8 = 8 then
      buf[5] := '1';
    if value and 4 = 4 then
      buf[6] := '1';
    if value and 2 = 2 then
      buf[7] := '1';
    if value and 1 = 1 then
      buf[8] := '1';
    Result := Result + buf;
    if FUsePipes then
      Result := Result + FPipeChar;
  end;
end;

Function TProgMemo.DecodeFromHEX: Ansistring;
var
  i: Integer;
begin
  Result := '';
  if FUsePipes then
  begin
    for i := 1 to Length(Text) div 3 do
      Result := Result + Chr(StrToInt('$' + Text[i * 3 - 2] + Text[i * 3 - 1]));
  end
  else
  begin
    for i := 1 to Length(Text) div 2 do
      Result := Result + Chr(StrToInt('$' + Text[i * 2 - 1] + Text[i * 2]));
  end;
end;

Function TProgMemo.EncodeToHEX: Ansistring;
var
  i: Integer;
begin
  Result := '';
  if FUsePipes then
  begin
    for i := 1 to Length(FBuffer) do
      Result := Result + IntToHex(Ord(FBuffer[i]), 2) + FPipeChar;
  end
  else
  begin
    for i := 1 to Length(FBuffer) do
      Result := Result + IntToHex(Ord(FBuffer[i]), 2);
  end;
end;

Procedure TProgMemo.DecodeContent;
begin
  case FMode of
    pmASCII:
      FBuffer := DecodeFromASCII;
    pmBitByte:
      FBuffer := DecodeFromBits;
    pmHEXByte:
      FBuffer := DecodeFromHEX;
  end;
end;

Procedure TProgMemo.EncodeContent;
begin
  case FMode of
    pmASCII:
      Text := EncodeToASCII;
    pmBitByte:
      Text := EncodeToBits;
    pmHEXByte:
      Text := EncodeToHEX;
  end;
end;

Procedure TProgMemo.SetMode(const AMode: TProgMemoMode);
begin
  Lines.BeginUpdate;
  DecodeContent;
  FMode := AMode;
  EncodeContent;
  Lines.EndUpdate;
end;

Procedure TProgMemo.SetUsePipes(const AUsePipes: Boolean);
begin
  Lines.BeginUpdate;
  DecodeContent;
  FUsePipes := AUsePipes;
  EncodeContent;
  Lines.EndUpdate;
end;

Procedure TProgMemo.SetPipeChar(const APipeChar: AnsiChar);
begin
  Lines.BeginUpdate;
  DecodeContent;
  FPipeChar := APipeChar;
  EncodeContent;
  Lines.EndUpdate;
end;

Procedure TProgMemo.KeyPress(var Key: Char);
begin
  if FMode = pmBitByte then
  begin
    if not((Key = '1') or (Key = '0') or (Key = #08)) then
      Key := #0;
  end;
end;

Procedure TProgMemo.Change;
begin
  //
  inherited;
end;

Constructor TProgMemo.Create(aOwner: TComponent);
begin
  inherited;
  FBuffer := '';
  FMode := pmASCII;
  FUsePipes := True;
  FPipeChar := '|';
end;

procedure Register;
begin
  RegisterComponents('LaciTools', [TProgMemo]);
end;

end.
