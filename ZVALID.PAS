Unit ZValid;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#          Validators          #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Uses
  Validate, MsgBox, Drivers, ZGlobals;

Type
  PZRangeValidator = ^TZRangeValidator;
  TZRangeValidator = Object(TFilterValidator)
    Min : Longint;
    Max : Longint;
    HexMode : Boolean;
    Constructor Init(AMin, AMax : Longint; AHexMode : Boolean);
    Procedure Error; virtual;
    Function IsValid(const S : String) : Boolean; virtual;
    Function Transfer(var S : String; Buffer : Pointer;
      Flag : TVTransfer) : Word; virtual;
  End;

  PStringValidator = ^TStringValidator;
  TStringValidator = object(TValidator)
    MaxLen : Integer;
    Constructor Init(AMaxLen : Integer);
    Procedure Error; virtual;
    Function IsValid(const S : String) : Boolean; virtual;
    Function Transfer(var S : String; Buffer : Pointer;
      Flag : TVTransfer) : Word; virtual;
  End;

Implementation

Constructor TStringValidator.Init(AMaxLen : Integer);

Begin
  Inherited Init;
  MaxLen := AMaxLen;
End; {of TStringValidator.Init}

Procedure TStringValidator.Error;

Begin
  MessageBox(#3'Error in string',nil,mfError or mfOkButton);
End; {of TStringValidateo.Error}

Function TStringValidator.IsValid(const S : String) : Boolean;

Var
  AnError : Boolean;

Begin
  AnError := False;
  UnformatStr(S,AnError);
  IsValid := not AnError;
End; {of TStringValidator.IsValid}

Function TStringValidator.Transfer(var S : String; Buffer : Pointer;
  Flag : TVTransfer) : Word;

Var
  AnError : Boolean;

Begin
  If Flag = vtSetData then
    S := String(Buffer^);
  If Flag = vtGetData then
    String(Buffer^) := UnformatStr(S,AnError);
  Transfer := 256;
End; {of TStringValidator.Transfer}

Function TZRangeValidator.Transfer(var S : String; Buffer : Pointer;
  Flag : TVTransfer) : Word;

Var
  Code : integer;

Begin
  If Flag = vtSetData then
    If HexMode then
      Begin
        FormatStr(S,'%x',Buffer^);
        S := '$'+S;
      End else
      FormatStr(S,'%d',Buffer^);
  If Flag = vtGetData then
    Val(S,Longint(Buffer^),code);
  Transfer := 4;
End; {of TZRangeValidator.Transfer}

Constructor TZRangeValidator.Init(AMin, AMax : Longint; AHexMode :
	Boolean);

Var
  TempHexMode : Boolean;

Begin
  Inherited Init(['0'..'9','A'..'F','a'..'f','$']);
  HexMode := AHexMode;
  Min := AMin;
  Max := AMax;
End; {of TZRangeValidator.Init}

Procedure TZRangeValidator.Error;

Var
  Range : record
    Min, Max : Longint;
  End;

Begin
  Range.Min := Min;
  Range.Max := Max;
  If HexMode then
    MessageBox(#3'Value is not in the range'#13#13#3+
      '$%x to $%x',@Range,mfError or mfOkButton) else
    MessageBox(#3'Value is not in the range'#13#13#3+
      '%d to %d',@Range,mfError or mfOkButton);
End; {of TZRangeValidator.Error}

Function TZRangeValidator.IsValid(const S : String) : Boolean;

Var
  Value : Longint;
  i : Integer;

Begin
  Val(S,Value,i);
  If (Value>=Min) and (Value<=Max) then
    IsValid := True else
    IsValid := False;
End; {of TZRangeValidator.IsValid}

End. {of Unit ZValid}

