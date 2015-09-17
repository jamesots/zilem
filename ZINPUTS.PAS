Unit ZInputs;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#         Input Lines          #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Uses
  Objects, Dialogs, Validate, Drivers, Views,
  ZValid, ZGlobals, ZConsts;

Type
  PAddressInputLine = ^TAddressInputLine;
  TAddressInputLine = object(TInputLine)
    Constructor Init(var Bounds : TRect; AHelpCtx : Word);
  End;

  PByteInputLine = ^TByteInputLine;
  TByteInputLine = Object(TInputLine)
    Constructor Init(var Bounds : TRect; AHelpCtx : Word);
  End;

  PStringInputLine = ^TStringInputLine;
  TStringInputLine = object(TInputLine)
    Constructor Init(var Bounds : TRect; AMaxLen : Integer;
      AHelpCtx : Word);
  End;

Implementation

Constructor TStringInputLine.Init(var Bounds : TRect; AMaxLen : Integer;
  AHelpCtx : Word);

Begin
  Inherited Init(Bounds,AMaxLen);
  Validator := New(PStringValidator,Init(AMaxLen));
  HelpCtx := AHelpCtx;
End; {of TStringInputLine.Init}

Constructor TAddressInputLine.Init(var Bounds : TRect; AHelpCtx : Word);

Begin
  Inherited Init(Bounds,6);
  Validator := New(PZRangeValidator,Init(0,MemorySize,Pref.Base=0));
  HelpCtx := AHelpCtx;
End; {of AddressInputLine.Init}

Constructor TByteInputLine.Init(var Bounds : TRect; AHelpCtx : Word);

Begin
  Inherited Init(Bounds,6);
  Validator := New(PZRangeValidator,Init(0,255,Pref.Base=0));
  HelpCtx := AHelpCtx;
End; {of TByteInputLine.Init}

End. {of Unit ZInputs}
