Unit Calc;

{ Calculator unit - 32 bit integers only    }
{ (c) 1993 James Ots                        }
{ Latest update - 18/11/93                  }

{$N+ E+}

Interface

Uses
  Objects, Views, Dialogs, Drivers;

Const

  {Number buttons are disableable - so < 255.}

  cmInsert0 = 100;
  cmInsert1 = 101;
  cmInsert2 = 102;
  cmInsert3 = 103;
  cmInsert4 = 104;
  cmInsert5 = 105;
  cmInsert6 = 106;
  cmInsert7 = 107;
  cmInsert8 = 108;
  cmInsert9 = 109;
  cmInsertA = 110;
  cmInsertB = 111;
  cmInsertC = 112;
  cmInsertD = 113;
  cmInsertE = 114;
  cmInsertF = 115;

  {Calculator functions.}

  cmClear = 10000;
  cmAllClear = 10001;
  cmDelete = 10007;
  cmMemoryStore = 10008;
  cmMemoryRecall = 10009;
  cmBase = 10012;
  cmEquals = 10010;

  {Single operand operators.}

  cmSign = 10004;
  cmNot = 10015;

  {Dual operand operators in order of precedence.
   Digit two shows the precedence for the operator.}

  cmMultiply = 11002;
  cmDivide = 11003;
  cmModulus = 11011;
  cmAdd = 12005;
  cmSubtract = 12006;
  cmAnd = 13013;
  cmOr = 13014;
  cmXor = 13016;

  {Base description constants}

  bsBin = ' Binary';
  bsHex = ' Hexadecimal';
  bsDec = ' Decimal';

Type

  {The Calculator object}

  PCalc = ^TCalc;
  TCalc = Object(TDialog)
    Constructor Init(P : TPoint);
  private
    TextPalette : char;
    DisplayStr, Mode : PString;
    DisplayNum : Longint;
    NumberDisplay, ModeDisplay : PParamText;
    BaseField : PButton;
    Reg : Array[1..6] of record
      Number : Longint;
      Operator : Integer;
    end;
    RegSize : integer;
    Entered : Boolean;
    CalcMem : longint;
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure UpdateDisplay;
    Procedure InsertNumber(CharNumber : integer);
    Procedure Clear;
    Procedure Base;
    Procedure AllClear;
    Procedure Sign;
    Procedure BNot;
    Procedure Delete;
    Procedure MemoryStore;
    Procedure MemoryRecall;
    Procedure Equals;
    Procedure Operate(Operator : integer);
    Procedure Calculate(Operator : integer);
  end;

{Cacluclator object methods}

Implementation

Constructor TCalc.Init(P : TPoint);

Var
  R : TRect;
  PPaletteText : PPalette;

Begin
  {Dialog}
  R.Assign(P.X,P.Y,P.X+51,P.Y+17);
  Inherited Init(R,'Calculator');

  {Base}
  New(Mode);
  Mode^ := bsDec;
  R.Assign(27,4,40,5);
  ModeDisplay := New(PParamText,Init(R,'%-12s',1));
  Insert(ModeDisplay);
  ModeDisplay^.SetData(Mode);

  {Disable to non-decimal buttons}
  DisableCommands([cmInsertA,cmInsertB,cmInsertC,cmInsertD,
    cmInsertE,cmInsertF]);

  {Initialize entered variable}
  Entered := False;

  {Number display}
  New(DisplayStr);
  DisplayNum := 0;
  R.Assign(16,2,49,3);
  NumberDisplay := New(PParamText,Init(R,'%32s',1));
  Insert(NumberDisplay);
  UpdateDisplay;

  PPaletteText := NumberDisplay^.GetPalette;
  PPaletteText^ := #4;

  {Initialize Register stack}

  RegSize := 1;
  Reg[1].Operator := 15000;

  {Buttons - top row}
  R.Assign(2,4,9,6);
  Insert(New(PButton,Init(R,'~D~',cmInsertD,bfNormal)));
  R.Assign(10,4,17,6);
  Insert(New(PButton,Init(R,'~E~',cmInsertE,bfNormal)));
  R.Assign(18,4,25,6);
  Insert(New(PButton,Init(R,'~F~',cmInsertF,bfNormal)));

  {Buttons - row 2}
  R.Assign(2,6,9,8);
  Insert(New(PButton,Init(R,'~A~',cmInsertA,bfNormal)));
  R.Assign(10,6,17,8);
  Insert(New(PButton,Init(R,'~B~',cmInsertB,bfNormal)));
  R.Assign(18,6,25,8);
  Insert(New(PButton,Init(R,'~C~',cmInsertC,bfNormal)));
  R.Assign(26,6,33,8);
  BaseField := New(PButton,Init(R,'BA~S~',cmBase,bfNormal));
  Insert(BaseField);
  R.Assign(34,6,41,8);
  Insert(New(PButton,Init(R,'BCK',cmDelete,bfNormal)));
  R.Assign(42,6,49,8);
  Insert(New(PButton,Init(R,'NE~G~',cmSign,bfNormal)));

  {Buttons - row 3}
  R.Assign(2,8,9,10);
  Insert(New(PButton,Init(R,'~7~',cmInsert7,bfNormal)));
  R.Assign(10,8,17,10);
  Insert(New(PButton,Init(R,'~8~',cmInsert8,bfNormal)));
  R.Assign(18,8,25,10);
  Insert(New(PButton,Init(R,'~9~',cmInsert9,bfNormal)));
  R.Assign(26,8,33,10);
  Insert(New(PButton,Init(R,'C~L~R',cmClear,bfNormal)));
  R.Assign(34,8,41,10);
  Insert(New(PButton,Init(R,'NE~W~',cmAllClear,bfNormal)));
  R.Assign(42,8,49,10);
  Insert(New(PButton,Init(R,'NO~T~',cmNot,bfNormal)));

  {Buttons - row 4}
  R.Assign(2,10,9,12);
  Insert(New(PButton,Init(R,'~4~',cmInsert4,bfNormal)));
  R.Assign(10,10,17,12);
  Insert(New(PButton,Init(R,'~5~',cmInsert5,bfNormal)));
  R.Assign(18,10,25,12);
  Insert(New(PButton,Init(R,'~6~',cmInsert6,bfNormal)));
  R.Assign(26,10,33,12);
  Insert(New(PButton,Init(R,'~*~',cmMultiply,bfNormal)));
  R.Assign(34,10,41,12);
  Insert(New(PButton,Init(R,'~/~',cmDivide,bfNormal)));
  R.Assign(42,10,49,12);
  Insert(New(PButton,Init(R,'A~N~D',cmAnd,bfNormal)));

  {Buttons - row 5}
  R.Assign(2,12,9,14);
  Insert(New(PButton,Init(R,'~1~',cmInsert1,bfNormal)));
  R.Assign(10,12,17,14);
  Insert(New(PButton,Init(R,'~2~',cmInsert2,bfNormal)));
  R.Assign(18,12,25,14);
  Insert(New(PButton,Init(R,'~3~',cmInsert3,bfNormal)));
  R.Assign(26,12,33,14);
  Insert(New(PButton,Init(R,'~+~',cmAdd,bfNormal)));
  R.Assign(34,12,41,14);
  Insert(New(PButton,Init(R,'~-~',cmSubtract,bfNormal)));
  R.Assign(42,12,49,14);
  Insert(New(PButton,Init(R,'~O~R',cmOr,bfNormal)));

  {Buttons - row 6}
  R.Assign(2,14,9,16);
  Insert(New(PButton,Init(R,'~0~',cmInsert0,bfNormal)));
  R.Assign(10,14,17,16);
  Insert(New(PButton,Init(R,'SA~V~',cmMemoryStore,bfNormal)));
  R.Assign(18,14,25,16);
  Insert(New(PButton,Init(R,'~R~CL',cmMemoryRecall,bfNormal)));
  R.Assign(26,14,33,16);
  Insert(New(PButton,Init(R,'~=~',cmEquals,bfNormal)));
  R.Assign(34,14,41,16);
  Insert(New(PButton,Init(R,'~M~OD',cmModulus,bfNormal)));
  R.Assign(42,14,49,16);
  Insert(New(PButton,Init(R,'~X~OR',cmXor,bfNormal)));
End;

Procedure TCalc.UpdateDisplay;

Var
  BinNum : Longint;

Begin
  If Mode^ = bsHex then
    FormatStr(DisplayStr^,'%8x',DisplayNum) else
  If Mode^ = bsDec then
    Str(DisplayNum,DisplayStr^) else
  If Mode^ = bsBin then
    begin
      DisplayStr^ := '';
      If DisplayNum < 0 then
        BinNum := -(MaxLongint-(DisplayNum-1)) else
        BinNum := DisplayNum;
      Repeat
        DisplayStr^ := chr($30+BinNum mod 2)+DisplayStr^;
        BinNum := BinNum div 2;
      Until BinNum = 0;
    end;
  NumberDisplay^.SetData(DisplayStr);
End;

Procedure TCalc.InsertNumber(CharNumber : integer);

Var
  TempNum : comp;

Begin
  If Entered then
    DisplayNum := 0;
  Entered := False;
  If DisplayNum < 0 then
    CharNumber := -CharNumber;
  If Mode^ = bsDec then
    TempNum := Int(DisplayNum)*10+CharNumber else
  If Mode^ = bsHex then
    TempNum := Int(DisplayNum)*16+CharNumber else
  If Mode^ = bsBin then
    TempNum := Int(DisplayNum)*2+CharNumber;
  If (TempNum <= MaxLongint) and (TempNum >= -MaxLongint-1) then
    Begin
      DisplayNum := Trunc(TempNum);
      UpdateDisplay;
    end;
End;

Procedure TCalc.Delete;

Begin
  If Not Entered then
    begin
      If Mode^ = bsDec then
        DisplayNum := DisplayNum div 10 else
      If Mode^ = bsHex then
        DisplayNum := DisplayNum div 16 else
      If Mode^ = bsBin then
        DisplayNum := DisplayNum div 2;
      UpdateDisplay;
    end;
End;

Procedure TCalc.BNot;

Begin
  Entered := True;
  DisplayNum := Not(DisplayNum);
  UpdateDisplay;
End;

Procedure TCalc.Sign;

Begin
  DisplayNum := -DisplayNum;
  If not(Mode^ = bsDec) then
    Entered := True;
  UpdateDisplay;
End;

Procedure TCalc.Base;

Begin
  Entered := True;
  BaseField^.Select;
  If Mode^ = bsDec then
    begin
      Mode^ := bsBin;
      DisableCommands([cmInsert2,cmInsert3,cmInsert4,cmInsert5,cmInsert6,
        cmInsert7,cmInsert8,cmInsert9]);
    end else
    If Mode^ = bsBin then
      begin
        Mode^ := bsHex;
         EnableCommands([cmInsert2,cmInsert3,cmInsert4,cmInsert5,cmInsert6,
          cmInsert7,cmInsert8,cmInsert9,cmInsertA,cmInsertB,cmInsertC,
          cmInsertD,cmInsertE,cmInsertF]);
      end else
      If Mode^ = bsHex then
        begin
          Mode^ := bsDec;
          DisableCommands([cmInsertA,cmInsertB,cmInsertC,cmInsertD,
            cmInsertE,cmInsertF]);
        end;
  ModeDisplay^.SetData(Mode);
  UpdateDisplay;
  {Need to convert the display to the write base now}
End;

Procedure TCalc.Clear;

Begin
  Entered := False;
  DisplayNum := 0;
  UpdateDisplay;
End;

Procedure TCalc.AllClear;

Begin
  DisplayNum := 0;
  RegSize := 1;
  Entered := False;
  UpdateDisplay;
End;

Procedure TCalc.MemoryStore;

Begin
  Entered := True;
  CalcMem := DisplayNum;
End;

Procedure TCalc.MemoryRecall;

Begin
  Entered := True;
  DisplayNum := CalcMem;
  UpdateDisplay;
End;

Procedure TCalc.Operate(Operator : integer);

Begin
  Entered := True;
  Inc(RegSize);
  Reg[RegSize].Operator := Operator;
  Reg[RegSize].Number := DisplayNum;
  Calculate(Operator);
  Reg[RegSize].Operator := Operator;
End;

Procedure TCalc.Calculate(Operator : integer);

Var
  Prec : integer;

Begin
  Prec := Operator div 1000;
  While ((Reg[RegSize-1].Operator div 1000) <= prec) and (RegSize>2) do
    begin
      Case Reg[RegSize-1].Operator of
        cmAnd : Reg[RegSize-1].Number :=
          Reg[RegSize-1].Number and Reg[RegSize].Number;
        cmOr : Reg[RegSize-1].Number :=
          Reg[RegSize-1].Number or Reg[RegSize].Number;
        cmXor : Reg[RegSize-1].Number :=
          Reg[RegSize-1].Number xor Reg[RegSize].Number;
        cmAdd : Reg[RegSize-1].Number :=
          Reg[RegSize-1].Number + Reg[RegSize].Number;
        cmSubtract : Reg[RegSize-1].Number :=
          Reg[RegSize-1].Number - Reg[RegSize].Number;
        cmMultiply : Reg[RegSize-1].Number :=
          Reg[RegSize-1].Number * Reg[RegSize].Number;
        cmDivide : Reg[RegSize-1].Number :=
          Reg[RegSize-1].Number div Reg[RegSize].Number;
        cmModulus : Reg[RegSize-1].Number :=
          Reg[RegSize-1].Number mod Reg[RegSize].Number;
      end;
      Dec(RegSize);
    end;
  DisplayNum := Reg[RegSize].Number;
  UpdateDisplay;
End;

Procedure TCalc.Equals;

Begin
  Operate(cmOr);
  Dec(RegSize);
End;

Procedure TCalc.HandleEvent(var Event : TEvent);

Begin
  Inherited HandleEvent(Event);
  If Event.What = evCommand then
    Begin
      Case Event.Command of
        cmClear :
          begin
            Clear;
            ClearEvent(Event);
          end;
        cmAllClear :
          begin
            AllClear;
            ClearEvent(Event);
          end;
        cmBase :
          begin
            Base;
            ClearEvent(Event);
          end;
        cmSign :
          begin
            Sign;
            ClearEvent(Event);
          end;
        cmMemoryStore :
          begin
            MemoryStore;
            ClearEvent(Event);
          end;
        cmMemoryRecall :
          begin
            MemoryRecall;
            ClearEvent(Event);
          end;
        cmEquals :
          begin
            Equals;
            ClearEvent(Event);
          end;
      end;
      If (Event.Command = cmAdd) or
          (Event.Command = cmSubtract) or
          (Event.Command = cmMultiply) or
          (Event.Command = cmDivide) or
          (Event.Command = cmModulus) or
          (Event.Command = cmAnd) or
          (Event.Command = cmOr) or
          (Event.Command = cmXor) then
        begin
          Operate(Event.Command);
          ClearEvent(Event);
        end;
      If (Event.Command >= 100) and (Event.Command <= 115) then
        begin
          InsertNumber(Event.Command-100);
          ClearEvent(Event);
        end;
    end;
    If ((Event.What = evKeyDown) and (Event.CharCode = #8)) or
      ((Event.What = evCommand) and (Event.Command = cmDelete)) then
      begin
        Delete;
        ClearEvent(Event);
      end;
End;

End.
