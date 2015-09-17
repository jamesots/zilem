Unit ZEngine;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#      The emulator engine     #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

{$I-,S-}

Interface

Uses
  Objects, ZTerminl, Drivers, ZConsts;

Const
  fSign = 128;
  fZero = 64;
  fHalf = 16;
  fParity = 4;
  fOver = 4;
  fSub = 2;
  fCarry = 1;
  Bit0 = 1;
  Bit1 = 2;
  Bit2 = 4;
  Bit3 = 8;
  Bit4 = 16;
  Bit5 = 32;
  Bit6 = 64;
  Bit7 = 128;

Type
  TARegs = Record          {Alternativeable Registers}
    Case integer of
      0 : (AF, BC, DE, HL : Word);
      1 : (Flags, A, C, B, E, D, L, H : Byte);
  End;
  TIRegs = Record    {Index and PC/SP Registers}
    Case integer of
      0 : (IX, IY, PC, SP : Word);
      1 : (IXl, IXh, IYl, IYh : Byte);
  End;
  TORegs = Record    {Other registers}
    R, I : Byte;
    IFF1, IFF2 : Boolean;
    IMode : Integer;
  End;

  PEngine = ^TEngine;
  TEngine = Object(TObject)
    ShiftState : ^Word;
    PZMem : Pointer;
    ZRegs : TARegs;    {Standard Z80 Registers}
    ARegs : TARegs;    {Alternative Z80 Registers}
    TempRegs : TARegs;{Store here while swapping}
    IRegs : TIRegs;
    ORegs : TORegs;
    Terminal : PZTerminal;
    Constructor Init(AZMem : Pointer; ATerminal : PZTerminal);
    Function Execute(const Instruction : Byte) : Byte;
    Procedure DoCALL(AWord : Word);
    Procedure DoPUSH(const AWord : Word);
    Procedure StoreByte(const AWord : Word; const AByte : Byte);
  End;

Implementation

Constructor TEngine.Init(AZMem : Pointer; ATerminal : PZTerminal);

Begin
  Inherited Init;
  PZMem := AZMem;
  Terminal := ATerminal;
  ShiftState := Ptr(Seg0040,$17);
End; {of TEngine.Init}

Procedure TEngine.DoPUSH(const AWord : Word);

Begin
  Dec(IRegs.SP);
  StoreByte(IRegs.SP,Hi(AWord));
  Dec(IRegs.SP);
  StoreByte(IRegs.SP,Lo(AWord));
End; {of TEngine.Execute|DoPUSH}

Procedure TEngine.StoreByte(const AWord : Word; const AByte : Byte);

Begin
  Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+AWord))^) := AByte;
End; {of TEngine.Execute|StoreByte}

Procedure TEngine.DoCALL(AWord : Word);

Begin
  DoPUSH(IRegs.PC);
  IRegs.PC := AWord;
End; {of TEngine.Execute|DoCALL}

Function TEngine.Execute(const Instruction : Byte) : Byte;

Var
  AByte : Byte;
  TempByte : Byte;
  TempWord : Word;
  E : ShortInt;
  
Procedure StoreWord(AWord : Word; BWord : Word);

Begin
  Byte((Ptr(Seg(PZMem^),Ofs(PZMem^)+AWord))^) := Lo(BWord);
  Byte((Ptr(Seg(PZMem^),Ofs(PZMem^)+Succ(AWord)))^) := Hi(BWord);
End; {of TEngine.Execute|StoreWord}

Function GetByte(AWord : Word) : Byte;

Begin
  GetByte := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+AWord))^);
End; {of TEngine.Execute|GetByte}

Function GetWord(AWord : Word) : Word;

Begin
  GetWord := Word((Ptr(Seg(PZMem^),Ofs(PZmem^)+AWord))^)+
              Word((Ptr(Seg(PZMem^),Ofs(PZmem^)+Succ(AWord)))^)*256;
End; {of TEngine.Execute|GetWord}

Function ReadByte : Byte;

Begin
  ReadByte := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+IRegs.PC))^);
  Inc(IRegs.PC);
End; {of TEngine.Execute|ReadByte}

Function ReadWord : Word;

Begin
  ReadWord := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+IRegs.PC))^) +
    Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Succ(IRegs.PC)))^)*256;
  Inc(IRegs.PC,2);
End; {of TEngine.Execute|ReadWord}

Function ReadOffset : ShortInt;

Begin
  ReadOffset := ShortInt((Ptr(Seg(PZMem^),Ofs(PZmem^)+IRegs.PC))^);
  Inc(IRegs.PC);
End; {of TEngine.Execute|ReadOffset}

Procedure DoOut(APort, AByte : Byte);

Begin
  Case APort of
    $00 : Terminal^.Control(AByte);
  End;
End; {of TEngine.Execute|DoOut}

Function DoIn(APort : Byte) : Byte;

Begin
  Case APort of
    $01 : If Terminal^.KeyStatus then
            DoIn := Byte(Terminal^.ReadChar) else
            DoIn := 0;
    $02 : If Terminal^.KeyStatus then
            DoIn := $FF else
            DoIn := $00;
    $03 : Begin
            Repeat
            Until Terminal^.KeyStatus;
            DoIn := Byte(Terminal^.ReadChar);
          End;
  End;
End; {of TEngine.Execute|DoIn}

Procedure Increment(var AByte : Byte);

Var
  Flags : Word;
  TempByte : Byte;

Begin
  TempByte := AByte;
  Asm
    INC TempByte
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  AByte := TempByte;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fHalf)) +
    (Flags and (fSign+fZero+fHalf));
  If (Flags and fOver) = fOver then
    ZRegs.Flags := ZRegs.Flags or 4 else
    ZRegs.Flags := ZRegs.Flags and not 4;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|Increment}

Procedure Decrement(Var AByte : Byte);

Var
  Flags : Word;
  TempByte : Byte;

Begin
  TempByte := AByte;
  Asm
    DEC TempByte
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  AByte := TempByte;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fHalf)) +
    (Flags and (fSign+fZero+fHalf));
  If (Flags and fOver) = fOver then
    ZRegs.Flags := ZRegs.Flags or 4 else
    ZRegs.Flags := ZRegs.Flags and not 4;
  ZRegs.Flags := ZRegs.Flags or fSub;
End; {of TEngine.Execute|Decrement}

Procedure AddHL(AWord : Word);

Var
  Flags : Word;
  LocHL : Word;

Begin
  LocHL := ZRegs.HL;
  Asm
    MOV AX,LocHL
    MOV DX,AWord
    ADD AX,DX
    MOV LocHL,AX
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.HL := LocHL;
  ZRegs.Flags := (ZRegs.Flags and not fCarry) +
    (Flags and fCarry);
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|AddHL}

Procedure AddA(AByte : Byte);

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    MOV AL,LocA
    MOV DL,AByte
    ADD AL,DL
    MOV LocA,AL
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fHalf+fCarry)) +
    (Flags and (fSign+fZero+fHalf+fCarry));
  If (Flags and fOver) = fOver then
    ZRegs.Flags := ZRegs.Flags or 4 else
    ZRegs.Flags := ZRegs.Flags and not 4;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|AdddA}

Procedure AdcA(AByte : Byte);

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    MOV AL,LocA
    MOV DL,AByte
    ADC AL,DL
    MOV LocA,AL
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fHalf+fCarry)) +
    (Flags and (fSign+fZero+fHalf+fCarry));
  If (Flags and fOver) = fOver then
    ZRegs.Flags := ZRegs.Flags or 4 else
    ZRegs.Flags := ZRegs.Flags and not 4;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|AdcA}

Procedure SubA(AByte : Byte);

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    MOV AL,LocA
    MOV DL,AByte
    SUB AL,DL
    MOV LocA,AL
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fHalf+fCarry)) +
    (Flags and (fSign+fZero+fHalf+fCarry));
  If (Flags and fOver) = fOver then
    ZRegs.Flags := ZRegs.Flags or 4 else
    ZRegs.Flags := ZRegs.Flags and not 4;
  ZRegs.Flags := ZRegs.Flags or fSub;
End; {of TEngine.Execute|SubA}

Procedure SbcA(AByte : Byte);

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    MOV AL,LocA
    MOV DL,AByte
    SBB AL,DL
    MOV LocA,AL
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fHalf+fCarry)) +
    (Flags and (fSign+fZero+fHalf+fCarry));
  If (Flags and fOver) = fOver then
    ZRegs.Flags := ZRegs.Flags or 4 else
    ZRegs.Flags := ZRegs.Flags and not 4;
  ZRegs.Flags := ZRegs.Flags or fSub;
End; {of TEngine.Execute|SbcA}

Procedure AndA(AByte : Byte);

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    MOV AL,LocA
    MOV DL,AByte
    AND AL,DL
    MOV LocA,AL
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags or fHalf;
  ZRegs.Flags := ZRegs.Flags and not fCarry;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|AndA}

Procedure XorA(AByte : Byte);

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    MOV AL,LocA
    MOV DL,AByte
    XOR AL,DL
    MOV LocA,AL
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fCarry;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|XorA}

Procedure OrA(AByte : Byte);

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    MOV AL,LocA
    MOV DL,AByte
    OR AL,DL
    MOV LocA,AL
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fCarry;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|OrA}

Procedure CpA(AByte : Byte);

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    MOV AL,LocA
    MOV DL,AByte
    CMP AL,DL
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fHalf+fCarry)) +
    (Flags and (fSign+fZero+fHalf+fCarry));
  If (Flags and fOver) = fOver then
    ZRegs.Flags := ZRegs.Flags or 4 else
    ZRegs.Flags := ZRegs.Flags and not 4;
  ZRegs.Flags := ZRegs.Flags or fSub;
End; {of TEngine.Execute|CpA}

Procedure DoDAA;

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  If (ZRegs.Flags and fSub) <> 0 then
  Asm
    MOV AL,LocA
    DAS
    MOV LocA,AL
    PUSHF
    POP AX
    MOV Flags,AX
  End else
  Asm
    MOV AL,LocA
    DAA
    MOV LocA,AL
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fHalf+fCarry+fParity)) +
    (Flags and (fSign+fZero+fHalf+fCarry+fParity));
End; {of TEngine.Execute|DoDAA}

Procedure DoRLCA;

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    ROL LocA,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not fCarry) +
    (Flags and fCarry);
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|DoRLCA}

Procedure DoRRCA;

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    ROR LocA,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|DoRRCA}

Procedure DoRLA;

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Flags := ZRegs.Flags;
  Asm
    MOV AX,Flags
    PUSH AX
    POPF
    RCL LocA,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|DoRLA}

Procedure DoRRA;

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Flags := ZRegs.Flags;
  Asm
    MOV AX,Flags
    PUSH AX
    POPF
    RCR LocA,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|DoRRA}

Procedure DoPOP(var AWord : Word);

Begin
  AWord := GetByte(IRegs.SP);
  Inc(IRegs.SP);
  AWord := AWord+256*GetByte(IRegs.SP);
  Inc(IRegs.SP);
End; {of TEngine.Execute|DoPOP}

Procedure DoRET;

Begin
  DoPOP(IRegs.PC);
End; {of TEngine.Execute|DoRET}

Procedure SectionB;

Var
  PByte : ^Byte;
  AByte : Byte;

Procedure DoRLC;

Var
  AByte : Byte;
  Flags : Word;

Begin
  AByte := PByte^;
  Asm
    ROL AByte,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  Asm
    CMP AByte,0  {To set the flags right}
  End;
  PByte^ := AByte;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionB|DoRLC}

Procedure DoRRC;

Var
  Flags : Word;
  AByte : Byte;

Begin
  AByte := PByte^;
  Asm
    ROR AByte,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  Asm
    CMP AByte,0  {To set the flags right}
  End;
  PByte^ := AByte;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionB|DoRRC}

Procedure DoRL;

Var
  Flags : Word;
  AByte : Byte;

Begin
  AByte := PByte^;
  Flags := ZRegs.Flags;
  Asm
    MOV AX,Flags
    PUSH AX
    POPF
    RCL AByte,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  Asm
    CMP AByte,0  {To set the flags right}
  End;
  PByte^ := AByte;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionB|DoRL}

Procedure DoRR;

Var
  Flags : Word;
  AByte : Byte;

Begin
  AByte := PByte^;
  Flags := ZRegs.Flags;
  Asm
    MOV AX,Flags
    PUSH AX
    POPF
    RCR AByte,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  Asm
    CMP AByte,0  {To set the flags right}
  End;
  PByte^ := AByte;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionB|DoRR}

Procedure DoSLA;

Var
  Flags : Word;
  AByte : Byte;

Begin
  AByte := PByte^;
  Asm
    SAL AByte,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  Asm
    CMP AByte,0  {To set the flags right}
  End;
  PByte^ := AByte;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionB|DoSLA}

Procedure DoSRA;

Var
  Flags : Word;
  AByte : Byte;

Begin
  AByte := PByte^;
  Asm
    SAR AByte,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  Asm
    CMP AByte,0  {To set the flags right}
  End;
  PByte^ := AByte;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionB|DoSRA}

Procedure DoSLL;

Var
  Flags : Word;
  AByte : Byte;

Begin
  AByte := PByte^;
  Asm
    SHL AByte,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  Asm
    CMP AByte,0  {To set the flags right}
  End;
  PByte^ := AByte;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionB|DoSLL}

Procedure DoSRL;

Var
  Flags : Word;
  AByte : Byte;

Begin
  AByte := PByte^;
  Asm
    SHR AByte,1
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fCarry)) +
    (Flags and (fCarry));
  Asm
    CMP AByte,0  {To set the flags right}
  End;
  PByte^ := AByte;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionB|DoSRL}

Procedure DoBIT(Bit : Byte);

Var
  Flags : Word;
  AByte : Byte;

Begin
  PByte^ := PByte^ xor Bit;
  AByte := PByte^;
  Asm
    CMP AByte,0
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  PByte^ := AByte;
  ZRegs.Flags := (ZRegs.Flags and not (fZero)) +
    (Flags and (fZero));
  ZRegs.Flags := ZRegs.Flags or fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionB|DoBIT}

Procedure DoRES(Bit : Byte);

Begin
  PByte^ := PByte^ and not Bit;
End; {of TEngine.Execute|SectionB|DoRES}

Procedure DoSET(Bit : Byte);

Begin
  PByte^ := PByte^ or Bit;
End; {of TEngine.Execute|SectionB|DoSET}

Begin
  AByte := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+IRegs.PC))^);
  Inc(IRegs.PC);
  Case AByte mod 8 of
    0 : PByte := Addr(ZRegs.B);
    1 : PByte := Addr(ZRegs.C);
    2 : PByte := Addr(ZRegs.D);
    3 : PByte := Addr(ZRegs.E);
    4 : PByte := Addr(ZRegs.H);
    5 : PByte := Addr(ZRegs.L);
    6 : PByte := Ptr(Seg(PZMem^),Ofs(PZMem^)+ZRegs.HL);
    7 : PByte := Addr(ZRegs.A);
  End;
  Case AByte div 8 of
    $0 : DoRLC;
    $1 : DoRRC;
    $2 : DoRL;
    $3 : DoRR;
    $4 : DoSLA;
    $5 : DoSRA;
    $6 : DoSLL;
    $7 : DoSRL;
    $8 : DoBIT(1);
    $9 : DoBIT(2);
    $A : DoBIT(4);
    $B : DoBIT(8);
    $C : DoBIT(16);
    $D : DoBIT(32);
    $E : DoBIT(64);
    $F : DoBIT(128);
    $10 : DoRES(1);
    $11 : DoRES(2);
    $12 : DoRES(4);
    $13 : DoRES(8);
    $14 : DoRES(16);
    $15 : DoRES(32);
    $16 : DoRES(64);
    $17 : DoRES(128);
    $18 : DoSET(1);
    $19 : DoSET(2);
    $1A : DoSET(4);
    $1B : DoSET(8);
    $1C : DoSET(16);
    $1D : DoSET(32);
    $1E : DoSET(64);
    $1F : DoSET(128);
  End;
End; {of TEngine.Execute|SectionB}

Procedure SectionE;

Var
  AByte : Byte;

Procedure SbcHL(AWord : Word);

Var
  Flags : Word;
  LocHL : Word;

Begin
  Asm
    MOV DX,AWord
    MOV AX,ZRegs.HL
    SBB AX,DX
    MOV LocHL,AX
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.HL := LocHL;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fCarry+fHalf)) +
    (Flags and (fSign+fZero+fCarry+fHalf));
  If (Flags and fOver) = fOver then
    ZRegs.Flags := ZRegs.Flags or 4 else
    ZRegs.Flags := ZRegs.Flags and not 4;
  ZRegs.Flags := ZRegs.Flags or fSub;
End; {of TEngine.Execute|SectionE|DoSbcHL}

Procedure AdcHL(AWord : Word);

Var
  Flags : Word;
  LocHL : Word;

Begin
  Asm
    MOV DX,AWord
    MOV AX,ZRegs.HL
    ADC AX,DX
    MOV LocHL,AX
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.HL := LocHL;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fCarry+fHalf)) +
    (Flags and (fSign+fZero+fCarry+fHalf));
  If (Flags and fOver) = fOver then
    ZRegs.Flags := ZRegs.Flags or 4 else
    ZRegs.Flags := ZRegs.Flags and not 4;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionE|DoAdcHL}

Procedure DoNEG;

Var
  Flags : Word;
  LocA : Byte;

Begin
  LocA := ZRegs.A;
  Asm
    NEG LocA;
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.A := LocA;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fCarry+fHalf)) +
    (Flags and (fSign+fZero+fCarry+fHalf));
  If (Flags and fOver) = fOver then
    ZRegs.Flags := ZRegs.Flags or 4 else
    ZRegs.Flags := ZRegs.Flags and not 4;
  ZRegs.Flags := ZRegs.Flags or fSub;
End; {of TEngine.Execute|SectionE|DoNEG}

Procedure DoRRD;

Var
  Flags : Word;
  LocA : Byte;

Begin
  TempByte := ZRegs.A;
  ZRegs.A := ZRegs.A or (GetByte(ZRegs.HL) and $F);
  StoreByte(ZRegs.HL,GetByte(ZRegs.HL) div $10 + (TempByte and $F) * $10);
  LocA := ZRegs.A;
  Asm
    CMP LocA,0
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fSub;
  ZRegs.Flags := ZRegs.Flags and not fHalf;
End; {of TEngine.Execute|SectionE|DoRRDHL}

Procedure DoRLD;

Var
  Flags : Word;
  LocA : Byte;

Begin
  TempByte := ZRegs.A;
  ZRegs.A := ZRegs.A or (GetByte(ZRegs.HL) and $F0);
  StoreByte(ZRegs.HL,GetByte(ZRegs.HL) * $10 + (TempByte and $F));
  LocA := ZRegs.A;
  Asm
    CMP LocA,0
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fSub;
  ZRegs.Flags := ZRegs.Flags and not fHalf;
End; {of TEngine.Execute|SectionE|DoRLDHL}

Procedure DoINr(var AByte : Byte);

Var
  Flags : Word;
  LocB : Byte;

Begin
  AByte := DoIN(ZRegs.C);
  LocB := ZRegs.B;
  Asm
    CMP LocB,0
    PUSHF
    POP AX
    MOV Flags,AX
  End;
  ZRegs.Flags := (ZRegs.Flags and not (fSign+fZero+fParity)) +
    (Flags and (fSign+fZero+fParity));
  ZRegs.Flags := ZRegs.Flags and not fHalf;
  ZRegs.Flags := ZRegs.Flags and not fSub;
End; {of TEngine.Execute|SectionE|DoINr}

Procedure DoINI;

Begin
  StoreByte(ZRegs.HL,DoIN(ZRegs.C));
  Inc(ZRegs.HL);
  Dec(ZRegs.B);
  If ZRegs.B = 0 then
    ZRegs.Flags := ZRegs.Flags or fZero else
  ZRegs.Flags := ZRegs.Flags and not fZero;
End; {of TEngine.Execute|SectionE|DoINI}

Procedure DoOUTI;

Begin
  Dec(ZRegs.B);
  DoOUT(ZRegs.C,GetByte(ZRegs.HL));
  Inc(ZRegs.HL);
  If ZRegs.B = 0 then
    ZRegs.Flags := ZRegs.Flags or fZero else
  ZRegs.Flags := ZRegs.Flags and not fZero;
End; {of TEngine.Execute|SectionE|DoOUTI}

Procedure DoIND;

Begin
  StoreByte(ZRegs.HL,DoIN(ZRegs.C));
  Dec(ZRegs.HL);
  Dec(ZRegs.B);
  If ZRegs.B = 0 then
    ZRegs.Flags := ZRegs.Flags or fZero else
  ZRegs.Flags := ZRegs.Flags and not fZero;
End; {of TEngine.Execute|SectionE|DoIND}

Procedure DoOUTD;

Begin
  Dec(ZRegs.B);
  DoOUT(ZRegs.C,GetByte(ZRegs.HL));
  Dec(ZRegs.HL);
  If ZRegs.B = 0 then
    ZRegs.Flags := ZRegs.Flags or fZero else
  ZRegs.Flags := ZRegs.Flags and not fZero;
End; {of TEngine.Execute|SectionE|DoOUTD}

Procedure DoLDI;

Begin
  StoreByte(ZRegs.DE,GetByte(ZRegs.HL));
  Inc(ZRegs.DE);
  Inc(ZRegs.HL);
  Dec(ZRegs.BC);
End; {of TEngine.Execute|SectionE|DoLDI}

Procedure DoLDD;

Begin
  StoreByte(ZRegs.DE,GetByte(ZRegs.HL));
  Dec(ZRegs.DE);
  Dec(ZRegs.HL);
  Dec(ZRegs.BC);
End; {of TEngine.Execute|SectionE|DoLDD}

Procedure DoCPI;

Begin
  CpA(GetByte(ZRegs.HL));
  Inc(ZRegs.HL);
  Dec(ZRegs.BC);
End; {of TEngine.Execute|SectionE|DoCPI}

Procedure DoCPD;

Begin
  CpA(GetByte(ZRegs.HL));
  Dec(ZRegs.HL);
  Dec(ZRegs.BC);
End; {of TEngine.Execute|SectionE|DoCPD}

Begin
  AByte := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+IRegs.PC))^);
  Inc(IRegs.PC);
  Case AByte of
    $40 : DoINr(ZRegs.B);
    $41 : DoOUT(ZRegs.C,ZRegs.B);
    $42 : SbcHL(ZRegs.BC);
    $43 : StoreWord(ReadWord,ZRegs.BC);
    $44 : DoNEG;
    $45 : Begin
            DoRET;
            ORegs.IFF1 := ORegs.IFF2;
          End;
    $46 : ORegs.IMode := 0;
    $47 : ORegs.I := ZRegs.A;
    $48 : DoINr(ZRegs.C);
    $49 : DoOUT(ZRegs.C,ZRegs.C);
    $4A : AdcHL(ZRegs.BC);
    $4B : ZRegs.BC := GetWord(ReadWord);
    $4D : DoRET; {RETI}
    $4F : ORegs.R := ZRegs.A;
    $50 : DoINr(ZRegs.D);
    $51 : DoOUT(ZRegs.C,ZRegs.D);
    $52 : SbcHL(ZRegs.DE);
    $53 : StoreWord(ReadWord,ZRegs.DE);
    $56 : ORegs.IMode := 1;
    $57 : Begin
            ZRegs.A := ORegs.I;
            If ORegs.IFF2 then
              ZRegs.Flags := ZRegs.Flags or fParity else
              ZRegs.Flags := ZRegs.Flags and not fParity;
          End;
    $58 : DoINr(ZRegs.E);
    $59 : DoOUT(ZRegs.C,ZRegs.E);
    $5A : AdcHL(ZRegs.DE);
    $5B : ZRegs.DE := GetWord(ReadWord);
    $5E : ORegs.IMode := 2;
    $5F : Begin
            ZRegs.A := ORegs.R;
            If ORegs.IFF2 then
              ZRegs.Flags := ZRegs.Flags or fParity else
              ZRegs.Flags := ZRegs.Flags and not fParity;
          End;
    $60 : DoINr(ZRegs.H);
    $61 : DoOUT(ZRegs.C,ZRegs.H);
    $62 : SbcHL(ZRegs.HL);
    $67 : DoRRD;
    $68 : DoINr(ZRegs.L);
    $69 : DoOUT(ZRegs.C,ZRegs.L);
    $6A : AdcHL(ZRegs.HL);
    $6F : DoRLD;
    $70 : DoINr(TempByte);
    $72 : SbcHL(IRegs.SP);
    $73 : StoreWord(ReadWord,IRegs.SP);
    $78 : DoINr(ZRegs.A);
    $79 : DoOUT(ZRegs.C,ZRegs.A);
    $7A : AdcHL(IRegs.SP);
    $7B : IRegs.SP := GetWord(ReadWord);
    $A0 : DoLDI;
    $A1 : DoCPI;
    $A2 : DoINI;
    $A3 : DoOUTI;
    $A8 : DoLDD;
    $A9 : DoCPD;
    $AA : DoIND;
    $AB : DoOUTD;
    $B0 : Repeat
            DoLDI;
          Until (ZRegs.BC=0);
    $B1 : Repeat
            DoCPI;
          Until (ZRegs.BC=0) or ((ZRegs.Flags and fZero) <> 0);
    $B2 : Repeat
            DoINI;
          Until (ZRegs.Flags and fZero) <> 0;
    $B3 : Repeat
            DoOUTI;
          Until (ZRegs.Flags and fZero) <> 0;
    $B8 : Repeat
            DoLDD;
          Until (ZRegs.BC=0);
     $B9 : Repeat
             DoCPD;
           Until (ZRegs.BC=0) or ((ZRegs.Flags and fZero) <> 0);
    $BA : Repeat
            DoIND;
          Until (ZRegs.Flags and fZero) <> 0;
    $BB : Repeat
            DoOUTD;
          Until (ZRegs.Flags and fZero) <> 0;
  End;
End; {of TEngine.Execute|SectionE}

Var
  TempReg : Word;
  TempE : ShortInt;
  HLChar : Char;
  OrigPC : Word;

Label
  ReadNextByte, FirstTime;

Begin
  Execute := exOk;
  OrigPC := IRegs.PC;
  HLChar := 'H';
  AByte := Instruction;
  Goto FirstTime;
ReadNextByte:
  AByte := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+IRegs.PC))^);
FirstTime:
  Inc(IRegs.PC);
  Inc(ORegs.R);
  Case AByte of
    $00 : begin end;
    $01 : ZRegs.BC := ReadWord;
    $02 : StoreByte(ZRegs.BC,ZRegs.A);
    $03 : Inc(ZRegs.BC);
    $04 : Increment(ZRegs.B);
    $05 : Decrement(ZRegs.B);
    $06 : ZRegs.B := ReadByte;
    $07 : DoRLCA;
    $08 : Begin {ex af,af'}
            TempReg := ZRegs.AF;
            ZRegs.AF := ARegs.AF;
            ARegs.AF := TempReg;
          End;
    $09 : AddHL(ZRegs.BC);
    $0A : ZRegs.A := GetByte(ZRegs.BC);
    $0B : Dec(ZRegs.BC);
    $0C : Increment(ZRegs.C);
    $0D : Decrement(Zregs.C);
    $0E : ZRegs.C := ReadByte;
    $0F : DoRRCA;
    $10 : Begin  {djnz}
            Dec(ZRegs.B);
            E := ReadOffset;
            If ZRegs.B <> 0 then
              IRegs.PC := IRegs.PC + E;
          End;
    $11 : ZRegs.DE := ReadWord;
    $12 : StoreByte(ZRegs.DE,ZRegs.A);
    $13 : Inc(ZRegs.DE);
    $14 : Increment(ZRegs.D);
    $15 : Decrement(ZRegs.D);
    $16 : ZRegs.D := ReadByte;
    $17 : DoRLA;
    $18 : IRegs.PC := IRegs.PC + ShortInt(ReadOffset);
    $19 :  AddHL(ZRegs.DE);
    $1A : ZRegs.A := GetByte(ZRegs.DE);
    $1B : Dec(ZRegs.DE);
    $1C : Increment(ZRegs.E);
    $1D : Increment(ZRegs.E);
    $1E : ZRegs.E := ReadByte;
    $1F : DoRRA;
    $20 : Begin  {jr nz,e}
            E := ReadOffset;
            If (ZRegs.Flags and fZero) = 0 then
              IRegs.PC := IRegs.PC + E;
          End;
    $21 : ZRegs.HL := ReadWord;
    $22 : Begin  {ld (nn),hl}
            StoreByte(ReadByte,ZRegs.L);
            StoreByte(ReadByte,ZRegs.H);
          End;
    $23 : Inc(ZRegs.HL);
    $24 : Increment(ZRegs.H);
    $25 : Decrement(ZRegs.H);
    $26 : ZRegs.H := ReadByte;
    $27 : DoDAA;
    $28 : Begin  {jr z,e}
            E := ReadOffset;
            If (ZRegs.Flags and fZero) <> 0 then
              IRegs.PC := IRegs.PC + E;
          End;
    $29 : AddHL(ZRegs.HL);
    $2A : ZRegs.HL := GetByte(ReadWord);
    $2B : Dec(ZRegs.HL);
    $2C : Increment(ZRegs.L);
    $2D : Decrement(ZRegs.L);
    $2E : ZRegs.L := ReadByte;
    $2F : ZRegs.A := Not ZRegs.A;
    $30 : Begin  {jr nc,e}
            E := ReadOffset;
            If (ZRegs.Flags and fCarry) = 0 then
              IRegs.PC := IRegs.PC + E;
          End;
    $31 : IRegs.SP := ReadWord;
    $32 : StoreByte(ReadWord,ZRegs.A);
    $33 : Inc(IRegs.SP);
    $34 : If HLChar = 'H' then
            Begin  {inc (hl)}
              TempByte := GetByte(ZRegs.HL);
              Increment(TempByte);
              StoreByte(ZRegs.HL,TempByte);
            End else
            Begin
              TempE := ShortInt(ReadByte);
              TempByte := GetByte(ZRegs.HL+TempE);
              Increment(TempByte);
              StoreByte(ZRegs.HL+TempE,TempByte);
            End;
    $35 : If HLChar = 'H' then
            Begin  {dec (hl)}
              TempByte := GetByte(ZRegs.HL);
              Decrement(TempByte);
              StoreByte(ZRegs.HL,TempByte);
            End else
            Begin
              TempE := ShortInt(ReadByte);
              TempByte := GetByte(ZRegs.HL+TempE);
              Decrement(TempByte);
              StoreByte(ZRegs.HL+TempE,TempByte);
            End;
    $36 : If HLChar = 'H' then
            StoreByte(ZRegs.HL,ReadByte) else
            StoreByte(ZRegs.HL+ShortInt(ReadByte),ReadByte);
    $37 : ZRegs.Flags := ZRegs.Flags or fCarry;
    $38 : Begin {jr c,e}
            E := ReadOffset;
            If (ZRegs.Flags and fCarry) <> 0 then
              IRegs.PC := IRegs.PC + E;
          End;
    $39 : AddHL(IRegs.SP);
    $3A : ZRegs.A := GetByte(ReadWord);
    $3B : Dec(IRegs.SP);
    $3C : Increment(ZRegs.A);
    $3D : Decrement(ZRegs.A);
    $3E : ZRegs.A := ReadByte;
    $3F : If (ZRegs.Flags and fCarry) = 0 then {ccf}
            ZRegs.Flags := ZRegs.Flags or fCarry else
            ZRegs.Flags := ZRegs.Flags and not fCarry;
    $40 : Begin End;  {ld b,b}
    $41 : ZRegs.B := ZRegs.C;
    $42 : ZRegs.B := ZRegs.D;
    $43 : ZRegs.B := ZRegs.E;
    $44 : ZRegs.B := ZRegs.H;
    $45 : ZRegs.B := ZRegs.L;
    $46 : If HLChar = 'H' then
            ZRegs.B := GetByte(ZRegs.HL) else
            ZRegs.B := GetByte(ZRegs.HL+ShortInt(ReadByte));
    $47 : ZRegs.B := ZRegs.A;
    $48 : ZRegs.C := ZRegs.B;
    $49 : Begin End;  {ld c,c}
    $4A : ZRegs.C := ZRegs.D;
    $4B : ZRegs.C := ZRegs.E;
    $4C : ZRegs.C := ZRegs.H;
    $4D : ZRegs.C := ZRegs.L;
    $4E : If HLChar = 'H' then
            ZRegs.C := GetByte(ZRegs.HL) else
            ZRegs.C := GetByte(ZRegs.HL+ShortInt(ReadByte));
    $4F : ZRegs.C := ZRegs.A;
    $50 : ZRegs.D := ZRegs.B;
    $51 : ZRegs.D := ZRegs.C;
    $52 : Begin End;  {ld d,d}
    $53 : ZRegs.D := ZRegs.E;
    $54 : ZRegs.D := ZRegs.H;
    $55 : ZRegs.D := ZRegs.L;
    $56 : If HLChar = 'H' then
            ZRegs.D := GetByte(ZRegs.HL) else
            ZRegs.D := GetByte(ZRegs.HL+ShortInt(ReadByte));
    $57 : ZRegs.D := ZRegs.A;
    $58 : ZRegs.E := ZRegs.B;
    $59 : ZRegs.E := ZRegs.C;
    $5A : ZRegs.E := ZRegs.D;
    $5B : Begin end;  {ld e,e}
    $5C : ZRegs.E := ZRegs.H;
    $5D : ZRegs.E := ZRegs.L;
    $5E : If HLChar = 'H' then
            ZRegs.E := GetByte(ZRegs.HL) else
            ZRegs.E := GetByte(ZRegs.HL+ShortInt(ReadByte));
    $5F : ZRegs.E := ZRegs.A;
    $60 : ZRegs.H := ZRegs.B;
    $61 : ZRegs.H := ZRegs.C;
    $62 : ZRegs.H := ZRegs.D;
    $63 : ZRegs.H := ZRegs.E;
    $64 : Begin End;  {ld h,h}
    $65 : ZRegs.H := ZRegs.L;
    $66 : If HLChar = 'X' then
            IRegs.IXh := GetByte(ZRegs.HL+ShortInt(ReadByte)) else
            If HLChar = 'Y' then
              IRegs.IYh := GetByte(ZRegs.HL+ShortInt(ReadByte)) else
              ZRegs.H := GetByte(ZRegs.HL);
    $67 : ZRegs.H := ZRegs.A;
    $68 : ZRegs.L := ZRegs.B;
    $69 : ZRegs.L := ZRegs.C;
    $6A : ZRegs.L := ZRegs.D;
    $6B : ZRegs.L := ZRegs.E;
    $6C : ZRegs.L := ZRegs.H;
    $6D : Begin End;  {ld l,l}
    $6E : If HLChar = 'X' then
            IRegs.IXl := GetByte(ZRegs.HL+ShortInt(ReadByte)) else
            If HLChar = 'Y' then
              IRegs.IYl := GetByte(ZRegs.HL+ShortInt(ReadByte)) else
              ZRegs.L := GetByte(ZRegs.HL);
    $6F : ZRegs.L := ZRegs.A;
    $70 : If HLChar = 'H' then
            StoreByte(ZRegs.HL,ZRegs.B) else
            StoreByte(ZRegs.HL+ShortInt(ReadByte),ZRegs.B);
    $71 : If HLChar = 'H' then
            StoreByte(ZRegs.HL,ZRegs.C) else
            StoreByte(ZRegs.HL+ShortInt(ReadByte),ZRegs.C);
    $72 : If HLChar = 'H' then
            StoreByte(ZRegs.HL,ZRegs.D) else
            StoreByte(ZRegs.HL+ShortInt(ReadByte),ZRegs.D);
    $73 : If HLChar = 'H' then
            StoreByte(ZRegs.HL,ZRegs.E) else
            StoreByte(ZRegs.HL+ShortInt(ReadByte),ZRegs.E);
    $74 : If HLChar = 'X' then
            StoreByte(ZRegs.HL+ShortInt(ReadByte),IRegs.IXh) else
            If HLChar = 'Y' then
              StoreByte(ZRegs.HL+ShortInt(ReadByte),IRegs.IYh) else
              StoreByte(ZRegs.HL,ZRegs.H);
    $75 : If HLChar = 'X' then
            StoreByte(ZRegs.HL+ShortInt(ReadByte),IRegs.IXl) else
            If HLChar = 'Y' then
              StoreByte(ZRegs.HL+ShortInt(ReadByte),IRegs.IYl) else
              StoreByte(ZRegs.HL,ZRegs.L);
    $76 : Execute := exHalt;
    $77 : If HLChar = 'H' then
            StoreByte(ZRegs.HL,ZRegs.A) else
            StoreByte(ZRegs.HL+ShortInt(ReadByte),ZRegs.A);
    $78 : ZRegs.A := ZRegs.B;
    $79 : ZRegs.A := ZRegs.C;
    $7A : ZRegs.A := ZRegs.D;
    $7B : ZRegs.A := ZRegs.E;
    $7C : ZRegs.A := ZRegs.H;
    $7D : ZRegs.A := ZRegs.L;
    $7E : If HLChar = 'H' then
            ZRegs.A := GetByte(ZRegs.HL) else
            ZRegs.A := GetByte(ZRegs.HL+ShortInt(ReadByte));
    $7F : Begin End;  {ld a,a}
    $80 : AddA(ZRegs.B);
    $81 : AddA(ZRegs.C);
    $82 : AddA(ZRegs.D);
    $83 : AddA(ZRegs.E);
    $84 : AddA(ZRegs.H);
    $85 : AddA(ZRegs.L);
    $86 : AddA(GetByte(ZRegs.HL));
    $87 : AddA(ZRegs.A);
    $88 : AdcA(ZRegs.B);
    $89 : AdcA(ZRegs.C);
    $8A : AdcA(ZRegs.D);
    $8B : AdcA(ZRegs.E);
    $8C : AdcA(ZRegs.H);
    $8D : AdcA(ZRegs.L);
    $8E : AdcA(GetByte(ZRegs.HL));
    $8F : AdcA(ZRegs.A);
    $90 : SubA(ZRegs.B);
    $91 : SubA(ZRegs.C);
    $92 : SubA(ZRegs.D);
    $93 : SubA(ZRegs.E);
    $94 : SubA(ZRegs.H);
    $95 : SubA(ZRegs.L);
    $96 : SubA(GetByte(ZRegs.HL));
    $97 : SubA(ZRegs.A);
    $98 : SbcA(ZRegs.B);
    $99 : SbcA(ZRegs.C);
    $9A : SbcA(ZRegs.D);
    $9B : SbcA(ZRegs.E);
    $9C : SbcA(ZRegs.H);
    $9D : SbcA(ZRegs.L);
    $9E : SbcA(GetByte(ZRegs.HL));
    $9F : SbcA(ZRegs.A);
    $A0 : AndA(ZRegs.B);
    $A1 : AndA(ZRegs.C);
    $A2 : AndA(ZRegs.D);
    $A3 : AndA(ZRegs.E);
    $A4 : AndA(ZRegs.H);
    $A5 : AndA(ZRegs.L);
    $A6 : AndA(GetByte(ZRegs.HL));
    $A7 : AndA(ZRegs.A);
    $A8 : XorA(ZRegs.B);
    $A9 : XorA(ZRegs.C);
    $AA : XorA(ZRegs.D);
    $AB : XorA(ZRegs.E);
    $AC : XorA(ZRegs.H);
    $AD : XorA(ZRegs.L);
    $AE : XorA(GetByte(ZRegs.HL));
    $AF : XorA(ZRegs.A);
    $B0 : OrA(ZRegs.B);
    $B1 : OrA(ZRegs.C);
    $B2 : OrA(ZRegs.D);
    $B3 : OrA(ZRegs.E);
    $B4 : OrA(ZRegs.H);
    $B5 : OrA(ZRegs.L);
    $B6 : OrA(GetByte(ZRegs.HL));
    $B7 : OrA(ZRegs.A);
    $B8 : CpA(ZRegs.B);
    $B9 : CpA(ZRegs.C);
    $BA : CpA(ZRegs.D);
    $BB : CpA(ZRegs.E);
    $BC : CpA(ZRegs.H);
    $BD : CpA(ZRegs.L);
    $BE : CpA(GetByte(ZRegs.HL));
    $BF : CpA(ZRegs.A);
    $C0 : If (ZRegs.Flags and fZero) = 0 then
      DoRET;
    $C1 : DoPOP(ZRegs.BC);
    $C2 : If (ZRegs.Flags and fZero) = 0 then
      IRegs.PC := ReadWord else
      ReadWord;
    $C3 : IRegs.PC := ReadWord;
    $C4 : If (ZRegs.Flags and fZero) = 0 then
      DoCALL(ReadWord) else
      ReadWord;
    $C5 : DoPUSH(ZRegs.BC);
    $C6 : AddA(ReadByte);
    $C7 : DoCALL(0);
    $C8 : If (ZRegs.Flags and fZero) <> 0 then
      DoRET;
    $C9 : DoRET;
    $CA : If (ZRegs.Flags and fZero) <> 0 then
      IRegs.PC := ReadWord else
      ReadWord;
    $CB : SectionB;
    $CC : If (ZRegs.Flags and fZero) <> 0 then
      DoCALL(ReadWord) else
      ReadWord;
    $CD : DoCALL(ReadWord);
    $CE : AdcA(ReadByte);
    $CF : DoCALL($8);
    $D0 : If (ZRegs.Flags and fCarry) = 0 then
      DoRET;
    $D1 : DoPOP(ZRegs.DE);
    $D2 : If (ZRegs.Flags and fCarry) = 0 then
      IRegs.PC := ReadWord else
      ReadWord;
    $D3 : DoOut(ReadByte,ZRegs.A);
    $D4 : If (ZRegs.Flags and fCarry) = 0 then
      DoCALL(ReadWord) else
      ReadWord;
    $D5 : DoPUSH(ZRegs.DE);
    $D6 : SubA(ReadByte);
    $D7 : DoCALL($10);
    $D8 : If (ZRegs.Flags and fCarry) <> 0 then
      DoRET;
    $D9 : Begin
            TempRegs := ZRegs;
            ZRegs := ARegs;
            ARegs := TempRegs;
          End;
    $DA : If (ZRegs.Flags and fCarry) <> 0 then
      IRegs.PC := ReadWord else
      ReadWord;
    $DB :
     ZRegs.A := DoIn(ReadByte);
    $DC : If (ZRegs.Flags and fCarry) <> 0 then
      DoCALL(ReadWord) else
      ReadWord;
    $DD : Begin
            If HLChar='H' then
              Begin
                TempReg := IRegs.IX;
                IRegs.IX := ZRegs.HL;
                ZRegs.HL := TempReg;
              End else
            If HLChar<>'Y' then
              Begin
                TempReg := IRegs.IY;
                IRegs.IY := IRegs.IX;
                IRegs.IX := TempReg;
              End;
            HLChar := 'X';
            If IRegs.PC < (OrigPC + 256) then
              Goto ReadNextByte;
          End;
    $DE : SbcA(ReadByte);
    $DF : DoCALL($18);
    $E0 : If (ZRegs.Flags and fParity) = 0 then
      DoRET;
    $E1 : DoPOP(ZRegs.HL);
    $E2 : If (ZRegs.Flags and fParity) = 0 then
      IRegs.PC := ReadWord else
      ReadWord;
    $E3 : Begin
            TempByte := ZRegs.H;
            ZRegs.H := GetByte(IRegs.SP);
            StoreByte(IRegs.SP,TempByte);
            TempByte := ZRegs.L;
            ZRegs.L := GetByte(Succ(IRegs.SP));
            StoreByte(Succ(IRegs.SP),TempByte);
          End;
    $E4 : If (ZRegs.Flags and fParity) = 0 then
      DoCALL(ReadWord) else
      ReadWord;
    $E5 : DoPUSH(ZRegs.HL);
    $E6 : AndA(ReadByte);
    $E7 : DoCALL($20);
    $E8 : If (ZRegs.Flags and fParity) <> 0 then
      DoRET;
    $E9 : IRegs.PC := ZRegs.HL;
    $EA : If (ZRegs.Flags and fParity) <> 0 then
      IRegs.PC := ReadWord else
      ReadWord;
    $EB : Begin
            TempReg := ZRegs.DE;
            ZRegs.DE := ZRegs.HL;
            ZRegs.HL := TempReg;
          End;
    $EC : If (ZRegs.Flags and fParity) <> 0 then
      DoCALL(ReadWord) else
      ReadWord;
    $ED : Begin
            If HLChar='X' then
              Begin
                TempReg := IRegs.IX;
                IRegs.IX := ZRegs.HL;
                ZRegs.HL := TempReg;
              End;
            If HLChar='Y' then
              Begin
                TempReg := IRegs.IY;
                IRegs.IY := ZRegs.HL;
                ZRegs.HL := TempReg;
              End;
            HLChar := 'H';
            SectionE;
          End;
    $EE : XorA(ReadByte);
    $EF : DoCALL($28);
    $F0 : If (ZRegs.Flags and fSign) = 0 then
      DoRET;
    $F1 : DoPOP(ZRegs.AF);
    $F2 : If (ZRegs.Flags and fSign) = 0 then
      IRegs.PC := ReadWord else
      ReadWord;
    $F3 :  Begin
            ORegs.IFF1 := False;
            ORegs.IFF2 := False;
          End;
    $F4 : If (ZRegs.Flags and fSign) = 0 then
      DoCALL(ReadWord) else
      ReadWord;
    $F5 : DoPUSH(ZRegs.AF);
    $F6 : OrA(ReadByte);
    $F7 : DoCALL($30);
    $F8 : If (ZRegs.Flags and fSign) <> 0 then
      DoRET;
    $F9 : IRegs.SP := ZRegs.HL;
    $FA : If (ZRegs.Flags and fSign) <> 0 then
      IRegs.PC := ReadWord else
      ReadWord;
    $FB : Begin
            ORegs.IFF1 := True;
            ORegs.IFF2 := True;
          End;
    $FC : If (ZRegs.Flags and fSign) <> 0 then
      DoCALL(ReadWord) else
      ReadWord;
    $FD : Begin
            If HLChar='H' then
              Begin
                TempReg := IRegs.IY;
                IRegs.IY := ZRegs.HL;
                ZRegs.HL := TempReg;
              End else
            If HLChar<>'X' then
              Begin
                TempReg := IRegs.IX;
                IRegs.IX := IRegs.IY;
                IRegs.IY := TempReg;
              End;
            HLChar := 'Y';
            If IRegs.PC < (OrigPC+256) then
              Goto ReadNextByte;
          End;
    $FE : CpA(ReadByte);
    $FF : DoCALL($38);
  End;
  If HLChar = 'Y' then
    Begin
      TempReg := IRegs.IY;
      IRegs.IY := ZRegs.HL;
      ZRegs.HL := TempReg;
    End else
  If HLChar = 'X' then
    Begin
      TempReg := IRegs.IX;
      IRegs.IX := ZRegs.HL;
      ZRegs.HL := TempReg;
    End;
  If CtrlBreakHit then
    Begin
      Execute := exBreak;
      CtrlBreakHit := False;
    End else
    If (ShiftState^ and (kbLeftShift or kbRightShift)) =
      (kbLeftShift or kbRightShift) then
      If (ShiftState^ and kbCtrlShift) = kbCtrlShift then
        Execute := exNMI else
        Execute := exInt;
End; {of TEngine.Execute}

End. {of Unit ZEngine}
