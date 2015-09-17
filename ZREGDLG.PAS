Unit ZRegDlg;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#     Register/Code Dialog     #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Uses
  Objects, Views, Dialogs, Drivers, ZEngine, ZGlobals, ZConsts, ZInputs,
  MsgBox;

Type
  PWord = ^Word;
  PByte = ^Byte;

  PRegisterInput = ^TRegisterInput;
  TRegisterInput = Object(TView)
    Register : PWord;
    Constructor Init(var Bounds : TRect; ARegister : PWord);
    Procedure Draw; virtual;
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure MoveLeft;
    Procedure MoveRight;
    Procedure Enter(const AChar : Char);
    Function ChangedCursor(GlobalPos : TPoint) : Boolean;
  End;

  PFlagInput = ^TFlagInput;
  TFlagInput = Object(TView)
    Register : PByte;
    FlagMask : Byte;
    Constructor Init(var Bounds : TRect; ARegister : PByte; AFlagMask :
      Byte);
    Procedure Draw; virtual;
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure Enter(const AChar : Char);
  End;

  PShowCode = ^TShowCode;
  TShowCode = Object(TView)
    PZMem : Pointer;
    PC : PWord;
    Constructor Init(var Bounds : TRect; APC : PWord; AZMem : Pointer);
    Procedure Draw; virtual;
  End;

  PRegistersDialog = ^TRegistersDialog;
  TRegistersDialog = Object(TDialog)
    Constructor Init(AZMem : Pointer; Engine : PEngine);
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure Close; virtual;
  End;

  PEnterCodeDialog = ^TEnterCodeDialog;
  TEnterCodeDialog = Object(TDialog)
    PZMem : Pointer;
    TempMem : Pointer;
    CodeInputLine : PInputLine;
    AddressInputLine : PAddressInputLine;
    Constructor Init(APZMem : Pointer; AnAddress : Word);
    Procedure HandleEvent(var Event : TEvent); virtual;
    Destructor Done; virtual;
  End;

  PCodeViewer = ^TCodeViewer;
  TCodeViewer = Object(TScroller)
    PZMem : Pointer;
    Engine : PEngine;
    StartAt : Word;
    CursorAt : Word;
    Constructor Init(var Bounds : TRect; AVScroller : PScrollBar;
      CPZMem : Pointer; var AnEngine : PEngine);
    Procedure Draw; virtual;
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure MoveDown;
    Procedure MoveUp;
    Procedure MoveToPC;
    Procedure ScrollDraw; virtual;
    Function ChangedCursor(GlobalPos : TPoint) : Boolean;
    Function ChangedPC(GlobalPos : TPoint) : Boolean;
    Procedure ChangePC;
    Procedure ReCalcCursor;
  End;

  PCodeWindow = ^TCodeWindow;
  TCodeWindow = Object(TWindow)
    Interior : PCodeViewer;
    PZMem : Pointer;
    Engine : PEngine;
    Constructor Init(var Bounds : TRect; CPZMem : Pointer;
      var AnEngine : PEngine);
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure Close; virtual;
  End;

Function OpCode(var AZMem : Pointer; Address : Word; var AString : String)
  : Byte;

Implementation

{#1=ld ,#2=jr ,#3=bit ,#4=res ,#5=set ,#6=call ,#7=jp ,
 #8=inc ,#9=dec ,#10=add ,#11=adc ,#12=sub ,#13=sbc ,
 #14=and ,#15=xor ,#16=or ,#17=cp ,#18=push ,#19=pop ,
 #20=rlc ,#21=rrc ,#22=rl ,#23=rr ,#24=sla ,#25=sra ,
 #26=sll ,#27=in ,#28=out ,#29=ret,#30=rst ,#31=hl,
 #128=h, #129=l}
{%w=word,
 %d=index displacement,
 %b=byte,
 %e=relative jump offset}
{dollarB=table as shown in Appendix A.B,
 dollarC=  "    "   "    "    "     A.C,
 dollarE=  "    "   "    "    "     A.E}
{show blanks as DB opcode byte,
 i.e. EDH 01H would be DB $ED  DB $01}

Const
  Convert : Array[1..30] of string =
   ('ld ','jr ','bit ','res ','set ','call ','jp ',
    'inc ','dec ','add ','adc ','sub ','sbc ',
    'and ','xor ','or ','cp ','push ','pop ',
    'rlc ','rrc ','rl ','rr ','sla ','sra ',
    'sll ','in ','out ','ret','rst ');
  OpCodes : Array[1..3,0..255] of string[10] =
    (('nop',#1'bc,%w',#1'(bc),a',#8'bc',#8'b',#9'b',
      #1'b,%b','rlca','ex af,af''',#10#31',bc',#1'a,(bc)',
      #9'bc',#8'c',#9'c',#1'c,%b','rrca','djnz %e',
      #1'de,%w',#1'(de),a',#8'de',#8'd',#9'd',#1'd,%b',
      'rla',#2'%e',#10#31',de',#1'a,(de)',#9'de',#8'e',
      #9'e',#1'e,%b','rra',#2'nz,%e',#1#31',%w',#1'(%w),'#31,
      #8#31,#8#128,#9#128,#1#128',%b','daa',#2'z,%e',
      #10#31','#31,#1#31',(%w)',#9#31,#8#129,#9#129,#1#129',%b',
      'cpl',#2'nc,%e',#1'sp,%w',#1'(%w),a',#8'sp',#8'('#31'%d)',
      #9'('#31'%d)',#1'('#31'%d),%b','scf',#2'c,%e',#10#31',sp',
      #1'a,(%w)',#9'sp',#8'a',#9'a',#1'a,%b','ccf',
      #1'b,b',#1'b,c',#1'b,d',#1'b,e',
      #1'b,'#128,#1'b,'#129,#1'b,('#31'%d)',#1'b,a',
      #1'c,b',#1'c,c',#1'c,d',#1'c,e',
      #1'c,'#128,#1'c,'#129,#1'c,('#31'%d)',#1'c,a',
      #1'd,b',#1'd,c',#1'd,d',#1'd,e',
      #1'd,'#128,#1'd,'#129,#1'd,('#31'%d)',#1'd,a',
      #1'e,b',#1'e,c',#1'e,d',#1'e,e',
      #1'e,'#128,#1'e,'#129,#1'e,('#31'%d)',#1'e,a',
      #1#128',b',#1#128',c',#1#128',d',#1#128',e',
      #1#128','#128,#1#128','#129,#1'h,('#31'%d)',#1#128',a',
      #1#129',b',#1#129',c',#1#129',d',#1#129',e',
      #1#129','#128,#1#129','#129,#1'l,('#31'%d)',#1#129',a',
      #1'('#31'%d),b',#1'('#31'%d),c',#1'('#31'%d),d',#1'('#31'%d),e',
      #1'('#31'%d),'#128,#1'('#31'%d),'#129,'halt',#1'('#31'%d),a',
      #1'a,b',#1'a,c',#1'a,d',#1'a,e',
      #1'a,'#128,#1'a,'#129,#1'a,('#31'%d)',#1'a,a',
      #10'a,b',#10'a,c',#10'a,d',#10'a,e',
      #10'a,'#128,#10'a,'#129,#10'a,('#31'%d)',#10'a,a',
      #11'a,b',#11'a,c',#11'a,d',#11'a,e',
      #11'a,'#128,#11'a,'#129,#11'a,('#31'%d)',#11'a,a',
      #12'b',#12'c',#12'd',#12'e',
      #12#128,#12#129,#12'('#31'%d)',#12'a',
      #13'a,b',#13'a,c',#13'a,d',#13'a,e',
      #13'a,'#128,#13'a,'#129,#13'a,('#31'%d)',#13'a,a',
      #14'b',#14'c',#14'd',#14'e',
      #14#128,#14#129,#14'('#31'%d)',#14'a',
      #15'b',#15'c',#15'd',#15'e',
      #15#128,#15#129,#15'('#31'%d)',#15'a',
      #16'b',#16'c',#16'd',#16'e',
      #16#128,#16#129,#16'('#31'%d)',#16'a',
      #17'b',#17'c',#17'd',#17'e',
      #17#128,#17#129,#17'('#31'%d)',#17'a',
      #29' nz',#19'bc',#7'nz,%w',#7'%w',#6'nz,%w',
      #18'bc',#10'a,%b',#30'0',#29' z',#29,
      #7'z,%w','$B',#6'z,%w',#6'%w',#11'a,%b',
      #30'8',#29' nc',#19'de',#7'nc,%w',#28'(%b),a',
      #6'nc,%w',#18'de',#12'%b',#30'10',#29' c',
      'exx',#7'c,%w',#27'a,(%b)',#6'c,%w','$C',
      #13'a,%b',#30'18',#29' po',#19#31,#7'po,%w',
      'ex (sp),'#31,#6'po,%w',#18#31,#14'%b',#30'20',
      #29' pe',#7'('#31')',#7'pe,%w','ex de,'#31,#6'pe,%w',
      '$E',#15'%b',#30'28',#29' p',#19'af',#7'p,%w',
      'di',#6'p,%w',#18'af',#16'%b',#30'30',#29' m',
      #1'sp,'#31,#7'm,%w','ei',#6'm,%w','$C',
      #17'%b',#30'38'),
     (#20'b',#20'c',#20'd',#20'e',
       #20#128,#20#129,#20'('#31'%d)',#20'a',
       #21'b',#21'c',#21'd',#21'e',
       #21#128,#21#129,#21'('#31'%d)',#21'a',
       #22'b',#22'c',#22'd',#22'e',
       #22#128,#22#129,#22'('#31'%d)',#22'a',
       #23'b',#23'c',#23'd',#23'e',
       #23#128,#23#129,#23'('#31'%d)',#23'a',
       #24'b',#24'c',#24'd',#24'e',
       #24#128,#24#129,#24'('#31'%d)',#24'a',
       #25'b',#25'c',#25'd',#25'e',
       #25#128,#25#129,#25'('#31'%d)',#25'a',
       #26'b',#26'c',#26'd',#26'e',
       #26#128,#26#129,#26'('#31'%d)',#26'a',
       's'#22'b','s'#22'c','s'#22'd','s'#22'e',
       's'#22#128,'s'#22#129,'s'#22'('#31'%d)','s'#22'a',
       #3'0,b',#3'0,c',#3'0,d',#3'0,e',
       #3'0,'#128,#3'0,'#129,#3'0,('#31'%d)',#3'0,a',
       #3'1,b',#3'1,c',#3'1,d',#3'1,e',
       #3'1,'#128,#3'1,'#129,#3'1,('#31'%d)',#3'1,a',
       #3'2,b',#3'2,c',#3'2,d',#3'2,e',
       #3'2,'#128,#3'2,'#129,#3'2,('#31'%d)',#3'2,a',
       #3'3,b',#3'3,c',#3'3,d',#3'3,e',
       #3'3,'#128,#3'3,'#129,#3'3,('#31'%d)',#3'3,a',
       #3'4,b',#3'4,c',#3'4,d',#3'4,e',
       #3'4,'#128,#3'4,'#129,#3'4,('#31'%d)',#3'4,a',
       #3'5,b',#3'5,c',#3'5,d',#3'5,e',
       #3'5,'#128,#3'5,'#129,#3'5,('#31'%d)',#3'5,a',
       #3'6,b',#3'6,c',#3'6,d',#3'6,e',
       #3'6,'#128,#3'6,'#129,#3'6,('#31'%d)',#3'6,a',
       #3'7,b',#3'7,c',#3'7,d',#3'7,e',
       #3'7,'#128,#3'7,'#129,#3'7,('#31'%d)',#3'7,a',
       #4'0,b',#4'0,c',#4'0,d',#4'0,e',
       #4'0,'#128,#4'0,'#129,#4'0,('#31'%d)',#4'0,a',
       #4'1,b',#4'1,c',#4'1,d',#4'1,e',
       #4'1,'#128,#4'1,'#129,#4'1,('#31'%d)',#4'1,a',
       #4'2,b',#4'2,c',#4'2,d',#4'2,e',
       #4'2,'#128,#4'2,'#129,#4'2,('#31'%d)',#4'2,a',
       #4'3,b',#4'3,c',#4'3,d',#4'3,e',
       #4'3,'#128,#4'3,'#129,#4'3,('#31'%d)',#4'3,a',
       #4'4,b',#4'4,c',#4'4,d',#4'4,e',
       #4'4,'#128,#4'4,'#129,#4'4,('#31'%d)',#4'4,a',
       #4'5,b',#4'5,c',#4'5,d',#4'5,e',
       #4'5,'#128,#4'5,'#129,#4'5,('#31'%d)',#4'5,a',
       #4'6,b',#4'6,c',#4'6,d',#4'6,e',
       #4'6,'#128,#4'6,'#129,#4'6,('#31'%d)',#4'6,a',
       #4'7,b',#4'7,c',#4'7,d',#4'7,e',
       #4'7,'#128,#4'7,'#129,#4'7,('#31'%d)',#4'7,a',
       #5'0,b',#5'0,c',#5'0,d',#5'0,e',
       #5'0,'#128,#5'0,'#129,#5'0,('#31'%d)',#5'0,a',
       #5'1,b',#5'1,c',#5'1,d',#5'1,e',
       #5'1,'#128,#5'1,'#129,#5'1,('#31'%d)',#5'1,a',
       #5'2,b',#5'2,c',#5'2,d',#5'2,e',
       #5'2,'#128,#5'2,'#129,#5'2,('#31'%d)',#5'2,a',
       #5'3,b',#5'3,c',#5'3,d',#5'3,e',
       #5'3,'#128,#5'3,'#129,#5'3,('#31'%d)',#5'3,a',
       #5'4,b',#5'4,c',#5'4,d',#5'4,e',
       #5'4,'#128,#5'4,'#129,#5'4,('#31'%d)',#5'4,a',
       #5'5,b',#5'5,c',#5'5,d',#5'5,e',
       #5'5,'#128,#5'5,'#129,#5'5,('#31'%d)',#5'5,a',
       #5'6,b',#5'6,c',#5'6,d',#5'6,e',
       #5'6,'#128,#5'6,'#129,#5'6,('#31'%d)',#5'6,a',
       #5'7,b',#5'7,c',#5'7,d',#5'7,e',
       #5'7,'#128,#5'7,'#129,#5'7,('#31'%d)',#5'7,a'),
     ('','','','','','','','','','','','','','','','',
       '','','','','','','','','','','','','','','','',
       '','','','','','','','','','','','','','','','',
       '','','','','','','','','','','','','','','','',
       #27'b,(c)',#28'(c),b',#13#31',bc',#1'(%w),bc',
       'neg','retn','im 0',#1'i,a',#27'c,(c)',#28'(c),c',
       #11#31',bc',#1'bc,(%w)','','reti','',#1'r,a',#27'd,(c)',
       #28'(c),d',#13#31',de',#1'(%w),de','','','im 1',#1'a,i',
       #27'e,(c)',#28'(c),e',#11#31',de',#1'de,(%w),','','','im 2',#1'a,r',
       #27#128',(c)',#28'(c),'#128,#13#31','#31,'','','','','rrd',
       #27#129',(c)',#28'(c),'#129,#11#31','#31,'','','','','rld',
       '['#27'(c)]','',#13#31',sp',#1'(%w),sp','','','','',
       #27'a,(c)',#28'(c),a',#11#31',sp',#1'sp,(%w)',
       '','','','',
       '','','','','','','','','','','','','','','','',
       '','','','','','','','','','','','','','','','',
       'ldi','cpi','ini','outi','','','','','ldd','cpd',
       'ind','outd','','','','','ldir','cpir',
       'inir','otir','','','','','lddr','cpdr',
       'indr','otdr','','','','',
       '','','','','','','','','','','','','','','','',
       '','','','','','','','','','','','','','','','',
       '','','','','','','','','','','','','','','','',
       '','','','','','','','','','','','','','','',''));

Function UpperCase(AString : String) : String;

Var
  i : Integer;

Begin
  If (Pref.Prefs and 4) = 4 then
  For i := 1 to length(AString) do
    AString[i] := UpCase(AString[i]);
  UpperCase := AString;
End; {of UpperCase}

Function DownCase(AChar : Char) : Char;

Begin
  If (AChar>='A') and (AChar<='Z') then
    AChar := Char(Byte(AChar)+(Byte('a')-Byte('A')));
  DownCase := AChar;
End; {of DownCase}

Function OpCode(var AZMem : Pointer; Address : Word;
  var AString : String) : Byte;

Label
  ReadNextByte;

Var
  AByte : Byte;
  Count : Integer;
  hlStr, hStr, lStr : String;
  i : Integer;

Procedure Section(Num : Integer);

Var
  i : Integer;
  FStr : String;
  Param : Longint;
  Sign : Char;

Begin
  i := 1;
  If length(OpCodes[Num,AByte]) = 0 then
    AString := '? Unknown ?' else
  While i <= length(OpCodes[Num,AByte]) do
    Begin
      If (OpCodes[Num,AByte,i]>#0) and (OpCodes[Num,AByte,i]<#31) then
        AString := AString + Convert[ord(OpCodes[Num,AByte,i])] else
      Case OpCodes[Num,AByte,i] of
        #31 : AString := AString+hlStr;
        #128 : AString := AString+hStr;
        #129 : AString := AString+lStr;
        '%' : begin
          inc(i);
          Case OpCodes[Num,AByte,i] of
            'b' : begin
                    Param := Byte((Ptr(Seg(AZMem^),Ofs(AZmem^)+
                      Address))^);
                    Inc(Address);
                    Inc(Count);
                    If Pref.Base = 0 then
                      Begin
                        FormatStr(FStr,'%02x',Param);
                        AString := AString+'$'+FStr;
                      End else
                      Begin
                        Str(Byte(Param),FStr);
                        AString := AString+FStr;
                      End;
                  end;
            'd' : if hlStr <> 'hl' then begin
                    Param := Byte((Ptr(Seg(AZMem^),Ofs(AZmem^)+
                      Address))^);
                    Inc(Address);
                    Inc(Count);
                    If Pref.Base = 0 then
                      Begin
                        FormatStr(FStr,'%02x',Param);
                        AString := AString+'+$'+FStr;
                      End else
                      Begin
                        Str(Byte(Param),FStr);
                        AString := AString+'+'+FStr;
                      End;
                  end;
            'w' : begin
                    Param := LongInt(Byte((Ptr(Seg(AZMem^),Ofs(AZMem^)+
                      Address))^)
                      + 256*Byte((Ptr(Seg(AZMem^),Ofs(AZMem^)+
                      Succ(Address)))^));
                    Inc(Address,2);
                    Inc(Count,2);
                    If Pref.Base = 0 then
                      Begin
                        FormatStr(FStr,'%04x',Param);
                        AString := AString+'$'+FStr;
                      End else
                      Begin
                        Str(Word(Param),FStr);
                        AString := AString+FStr;
                      End;
                  end;
            'e' : begin
                    Param := Word(ShortInt((Ptr(Seg(AZMem^),Ofs(AZMem^)+
                      Address))^) + Succ(Address));
                    Inc(Address);
                    Inc(Count);
                    If Pref.Base = 0 then
                      Begin
                        FormatStr(FStr,'%04x',Param);
                        AString := AString+'$'+FStr;
                      End else
                      Begin
                        Str(Word(Param),FStr);
                        AString := AString+FStr;
                      End;
                  end;
          end;
         end;
      else
        AString := AString+OpCodes[Num,AByte,i];
      end;
      Inc(i);
    End;
End; {of OpCode|Section}

Var
  OrigAdd : Word;
  Unknown : Boolean;

Begin
  OrigAdd := Address;
  Unknown := False;
  hlStr := 'hl';
  hStr := 'h';
  lStr := 'l';
  AString := '';
  Count := 0;
ReadNextByte:   {This is the only way to do this bit sensibly - using a goto}
  AByte := Byte((Ptr(Seg(AZMem^),Ofs(AZmem^)+Address))^);
  Inc(Address);
  Inc(Count);
  If AByte = $DD then
    begin
      hlStr := 'ix';
      hStr := 'ixh';
      lStr := 'ixl';
      If Address<(OrigAdd+256) then
        goto ReadNextByte else
        Unknown := True;
    end;
  If AByte = $FD then
    begin
      hlStr := 'iy';
      hStr := 'iyh';
      lStr := 'iyl';
      If Address<(OrigAdd+256) then
        goto ReadNextByte else
        Unknown := True;
    end;
  If AByte = $cb then
    Begin
      AByte := Byte((Ptr(Seg(AZMem^),Ofs(AZmem^)+Address))^);
      Inc(Address);
      Inc(Count);
      Section(2)
    End else
    If AByte = $ed then
      Begin
        AByte := Byte((Ptr(Seg(AZMem^),Ofs(AZmem^)+Address))^);
        Inc(Address);
        Inc(Count);
        Section(3)
      End else
      Section(1);
  If Unknown then
    Begin
      AString := '? Unknown ?';
      Count := 1;
    End;
  AString := UpperCase(AString);
  OpCode := Count;
End; {of OpCode}

Function UnCode(var AZMem : Pointer; Address : Word;
  AString : String) : Byte;

Var
  i : Integer;
  NumberStr : String;
  Number : Array[1..2] of Word;
  LastNum : Integer;
  NumberType : Array[1..2] of Char;
  LastNumType : Integer;
  Numbers : Set of '0'..'z';
  XY : Char;
  Code : Integer;  {Error code and opcode!}
  Table : Integer;
  Found : Boolean;
  WrongNum : Boolean;
  AStr : String;
  ANum : Word;
  ErrorCode : Integer;
  hStr,lStr,hlStr : String;

Begin
  LastNum := 0;
  XY := ' ';
  i := 1;
  AString := AString+' ';            {make sure it doesn't try looking at
                                      a non-existent character}
  While i <= Length(AString) do
    Begin

      If (AString[i] = #$27) {apostrophe} and      {read character bytes}
        (length(AString) >= (i+2)) and (AString[i+2] = #$27) then
        Begin
          Inc(LastNum);
          Number[LastNum] := Word(Ord(AString[succ(i)]));
          AString := Copy(AString,1,Pred(i)) + '%%' + Copy(AString,i+3,
            length(AString)-i-2);
          Inc(i,3);
        End;

      If AString[i] = ' ' then                   {remove spaces}
        If i = 1 then
          Begin
            AString := Copy(AString,2,length(AString)-1);
            Dec(i);
          End else
        If i = length(AString) then
          AString := Copy(AString,1,Pred(i)) else
        If (AString[Succ(i)] = ',') or (AString[succ(i)] = ')') or
          (AString[succ(i)] = ' ') then
          Begin
            AString := Copy(AString,1,Pred(i)) + Copy(AString,succ(i),
              length(AString)-i);
            Dec(i);
          End else
        If (AString[Pred(i)] = ',') or (AString[Pred(i)] = '(') or
          (AString[Pred(i)] = ' ') then
          AString := Copy(AString,1,Pred(i)) + Copy(AString,succ(i),
            length(AString)-i);

      AString[i] := DownCase(AString[i]);       {convert to lower case}

      If AString[i] in ['0'..'9','$'] then
        Begin                                    {read numbers}
          AString[i] := UpCase(AString[i]);
          If AString[i]='$' then
            Numbers := ['0'..'9','A'..'F','a'..'f'] else
            Numbers := ['0'..'9'];
          NumberStr := AString[i];
          AString[i] := '%';
          Inc(i);
          AString[i] := UpCase(AString[i]);
          While AString[i] in Numbers do
            Begin
              NumberStr := NumberStr + AString[i];
              Inc(i);
            End;
          AString := Copy(AString,1,i-length(NumberStr)) + '%' +
            Copy(AString,i,length(AString)-pred(i));
          Inc(LastNum);
          Val(NumberStr,Number[LastNum],code);
          i := i - length(NumberStr) + 2;
        End;

      If (AString[i] = 'i') and ((AString[Succ(i)]='x') or
        (AString[Succ(i)]='y')) then              {check indexes}
        Begin
          Inc(i);
          xy := AString[i];
          If AString[Succ(i)]='+' then
            AString := Copy(AString,1,i)+
              Copy(AString,i+2,length(AString)-succ(i));
        End;

      Inc(i);
    End;
  If AString[length(AString)]=' ' then  {remove the final space}
    Dec(AString[0]);

  Table := 1;
  Code := 0;
  Found := False;
  Repeat                      {search for OpCode}
    WrongNum := False;
    NumberStr := '';
    If xy=' ' then
      Begin
        hStr := 'h';
        lStr := 'l';
        hlStr := 'hl';
      End else
    If xy='x' then
      Begin
        hStr := 'ixh';
        lStr := 'ixl';
        hlStr := 'ix';
      End else
    If xy='y' then
      Begin
        hStr := 'iyh';
        lStr := 'iyl';
        hlStr := 'iy';
      End;
    LastNumType := 0;
    For i := 1 to length(OpCodes[table,code]) do
      Begin
        If (OpCodes[table,code,i] > #0) and (OpCodes[table,code,i] < #31)
          then
          NumberStr := NumberStr + Convert[Ord(OpCodes[table,code,i])]
            else
          Case OpCodes[table,code,i] of
            #31 : NumberStr := NumberStr+hlStr;
            #128 : NumberStr := NumberStr+hStr;
            #129 : NumberStr := NumberStr+lStr;
            '%' : begin
              inc(i);
              If not ((OpCodes[table,code,i] = 'd') and (xy=' ')) then
                Begin
                  NumberStr := NumberStr+'%%';
                  Inc(LastNumType);
                  NumberType[LastNumType] := OpCodes[table,code,i];
                End;
            End;
          Else
            If OpCodes[table,code,i] in ['0'..'9'] then
              Begin
                AStr := OpCodes[table,code,i];
                If OpCodes[table,code,succ(i)] in ['0'..'9'] then
                  AStr := AString + OpCodes[table,code,succ(i)];
                Val(AStr,ANum,ErrorCode);
                If ANum <> Number[1] then
                  WrongNum := True;
                NumberStr := NumberStr + '%%';
                Inc(LastNumType);
                NumberType[LastNumType] := 'n';  {a number!!}
                If OpCodes[table,code,succ(i)] in ['0'..'9'] then
                  Inc(i);
              End else
              NumberStr := NumberStr + OpCodes[table,code,i];
          End;
      End;
    If (NumberStr = AString) and (LastNumType=LastNum) and
      not(length(AString)=0) and not WrongNum then
      Found := True else
      Begin
        Inc(code);
        If Code > 255 then
          Begin
            Code := 0;
            Inc(Table);
          End;
      End;
  Until Found or (Table=4);
  If Found then
    Begin
      i := 1;                             {Encode into memory}
      If xy='x' then
        Begin
          Byte((Ptr(Seg(AZMem^),Ofs(AZmem^)+Address))^) := $DD;
          Inc(Address);
          Inc(i);
        End else
      If xy='y' then
        Begin
          Byte((Ptr(Seg(AZMem^),Ofs(AZmem^)+Address))^) := $FD;
          Inc(Address);
          Inc(i);
        End;
      If Table = 2 then
        Begin
          Byte((Ptr(Seg(AZMem^),Ofs(AZmem^)+Address))^) := $CB;
          Inc(Address);
          Inc(i);
        End else
      If Table = 3 then
        Begin
          Byte((Ptr(Seg(AZMem^),Ofs(AZmem^)+Address))^) := $ED;
          Inc(Address);
          Inc(i);
        End;
      Byte((Ptr(Seg(AZMem^),Ofs(AZmem^)+Address))^) := Code;
      Inc(Address);
      Inc(i);
      For Code := 1 to LastNum do
        Begin
          Case NumberType[Code] of
            'e' : Begin
                    ShortInt((Ptr(Seg(AZMem^),Ofs(AZMem^)+Address))^) :=
                      ShortInt(Word(Number[Code])-succ(Address));
                    Inc(Address);
                    Inc(i);
                  End;
            'b' : Begin
                    Byte((Ptr(Seg(AZMem^),Ofs(AZMem^)+Address))^) :=
                      Byte(Number[Code]);
                    Inc(Address);
                    Inc(i);
                  End;
            'w' : Begin
                    Byte((Ptr(Seg(AZMem^),Ofs(AZMem^)+Address))^) :=
                      Lo(Number[Code]);
                    Inc(Address);
                    Byte((Ptr(Seg(AZMem^),Ofs(AZMem^)+Address))^) :=
                      Hi(Number[Code]);
                    Inc(Address);
                    Inc(i,2);
                  End;
            'd' : Begin
                    ShortInt((Ptr(Seg(AZMem^),Ofs(AZMem^)+Address))^) :=
                      ShortInt(Number[Code]);
                    Inc(Address);
                    Inc(i,2);
                  End;
          End
        End;
      UnCode := Pred(i);
    End else
    UnCode := 0;
End; {of Uncode}

{************************************************************************}
{************************************************************************}

Procedure TEnterCodeDialog.HandleEvent(var Event : TEvent);

Var
  ANum : Longint;
  AString : String[18];
  ALength : Byte;
  ACount : Word;

Begin
  Inherited HandleEvent(Event);
  If (Event.What = evCommand) and (Event.Command = cmEnterCode)
    and AddressInputLine^.Valid(cmOk) then
    Begin
      AddressInputLine^.GetData(ANum);
      CodeInputLine^.GetData(AString);
      ALength := UnCode(TempMem,0,AString);
      If ALength = 0 then
        Begin
          MessageBox(#3'Error in mnemonic,'#13#13+
            #3'try again.',nil,mfError or mfOkButton);
          CodeInputLine^.SelectAll(True);
        End else
        Begin
          Inc(ANum,UnCode(PZMem,Word(ANum),AString));
          If ANum>$FFFF then
            ANum := 0;
          OpCode(PZMem,ANum,AString);
          CodeInputLine^.SetData(AString);
        End;
      AddressInputLine^.SetData(ANum);
      ClearEvent(Event);
      Message(Owner^.Owner,evCommand,cmRedrawCode,@Self);
    End;
End; {of TEnterCodeDialog.HandleEvent}

Destructor TEnterCodeDialog.Done;

Begin
  Inherited Done;
  FreeMem(TempMem,10);
End;

Constructor TEnterCodeDialog.Init(APZMem : Pointer; AnAddress : Word);

Var
  R : TRect;
  CodeButton : PButton;
  ANum : Longint;
  AString : String;

Begin
  R.Assign(0,0,28,12);
  Inherited Init(R,'Enter Code');
  Options := Options or ofCentered;
  PZMem := APZMem;
  
  GetMem(TempMem,10);

  R.Assign(3,3,23,4);
  CodeInputLine := New(PInputLine,Init(R,18));
  Insert(CodeInputLine);
  CodeInputLine^.HelpCtx := hcCodeInputLine;
  OpCode(PZMem,AnAddress,AString);
  CodeInputLine^.SetData(AString);
  R.Assign(23,3,26,4);
  Insert(New(PHistory,Init(R,CodeInputLine,hsCodeInputLine)));
  R.Assign(2,2,11,3);
  Insert(New(PLabel,Init(R,'~Z~80 Code',CodeInputLine)));

  R.Assign(3,6,13,7);
  AddressInputLine := New(PAddressInputLine,Init(R,hcCodeAddress));
  Insert(AddressInputLine);
  R.Assign(2,5,6,6);
  Insert(New(PLabel,Init(R,'~a~t',AddressInputLine)));

  ANum := Longint(AnAddress);
  AddressInputLine^.SetData(ANum);

  R.Assign(2,8,12,10);
  CodeButton := New(PButton,Init(R,'~E~nter',cmEnterCode,bfDefault));
  CodeButton^.HelpCtx := hcEnterButton;
  Insert(CodeButton);

  R.Assign(14,8,24,10);
  CodeButton := New(PButton,Init(R,'~F~inish',cmCancel,bfNormal));
  CodeButton^.HelpCtx := hcFinishButton;
  Insert(CodeButton);

  SelectNext(False);
End; {of TEnterCodeDialog.Init}

{************************************************************************}
{************************************************************************}

Procedure TCodeWindow.Close;

Begin
  If Valid(cmClose) then
    Hide;
End;

Procedure TCodeWindow.HandleEvent(var Event : TEvent);

Begin
  Inherited HandleEvent(Event);
  If Event.What = evCommand then
    case Event.Command of
      cmRedrawCode :
        Begin
          ReDraw;
          ClearEvent(Event);
        End;
      cmAssemble :
      Begin
        Owner^.ExecView(New(PEnterCodeDialog,Init(PZMem,Interior^.
          CursorAt)));
        Interior^.ReCalcCursor;
        ClearEvent(Event);
      End;
    End;
End; {of TCodeWindow.HandleEvent}

Constructor TCodeWindow.Init(var Bounds : TRect; CPZMem : Pointer;
  var AnEngine : PEngine);

Var
  R : TRect;
  ScrollBar : PScrollBar;

Begin
  Inherited Init(Bounds,'Z80 Code',3);
  HelpCtx := hcCodeWindow;
  PZMem := CPZMem;
  Engine := AnEngine;
  ScrollBar := StandardScrollBar(sbVertical);
  Insert(ScrollBar);
  GetExtent(R);
  R.Grow(-1,-1);
  Interior := New(PCodeViewer, Init(R,ScrollBar,PZMem,AnEngine));
  Insert(Interior);
End; {of TCodeWindow.Init}

{************************************************************************}
{************************************************************************}

Procedure TCodeViewer.MoveToPC;

Begin
  If (Pref.Prefs and 8) = 8 then
    Begin
      StartAt := Engine^.IRegs.PC;
      CursorAt := StartAt;
      Cursor.Y := 0;
      SetCursor(0,Cursor.Y);
      Delta.Y := Integer(StartAt div 2);
      VScrollBar^.SetValue(Integer(CursorAt div 2));
    End;
  DrawView;
End; {of TCodeViewer.MoveToPC}

Procedure TCodeViewer.ReCalcCursor;

Var
  i : Integer;
  AString : String;

Begin
  CursorAt := StartAt;
  For i := 1 to Cursor.Y do
     CursorAt := CursorAt + OpCode(PZMem,CursorAt,AString);
End;

Constructor TCodeViewer.Init(var Bounds : TRect; AVScroller : PScrollBar;
  CPZMem : Pointer; var AnEngine : PEngine);

Begin
  Inherited Init(Bounds,nil,AVScroller);
  Engine := AnEngine;
  GrowMode := gfGrowHiX + gfGrowHiY;
  Options := Options or ofTileable;
  PZMem := CPZMem;
  Cursor.X := 0;
  Cursor.Y := 0;
  StartAt := 0;
  CursorAt := 0;
  SetLimit(-$8000,$7FFF);
  VScrollBar^.SetRange($0,$7FFF);
  VScrollBar^.SetValue($0);
  Delta.Y := -$8000;
  ShowCursor;
End; {of TCodeViewer.Init}

Procedure TCodeViewer.Draw;

Var
  DrawBuf : TDrawBuffer;
  Colour : Word;
  X,Y : Word;
  I : Word;
  S,T : String;

Begin
  I := StartAt;
  For Y := 0 to Pred(Size.Y) do
    Begin
        Begin
          If I = Engine^.IRegs.PC then
            Colour := GetColor(2) else
            Colour := GetColor(1);
          FormatStr(S,'%04x',I);
          S := ' '+S+'  ';
          I := I + OpCode(PZMem,I,T);
          S := S+T;
          While length(S)<Size.X do
            S := S+' ';
        End;
      MoveStr(DrawBuf,S,Colour);
      WriteLine(0,Y,Size.X,1,DrawBuf);
    End;
End; {of TCodeViewer.Draw}

Procedure TCodeViewer.MoveDown;

Var
  AString : String;

Begin
  Inc(Cursor.Y);
  CursorAt := CursorAt + OpCode(PZMem,CursorAt,AString);
  If Cursor.Y > Pred(Size.Y) then
    Begin
      Dec(Cursor.Y);
      StartAt := StartAt+OpCode(PZMem,StartAt,AString);
      DrawView;
    End;
  SetCursor(0,Cursor.Y);
  Delta.Y := Integer(StartAt div 2);
  VScrollBar^.SetValue(Integer(CursorAt div 2));
End; {of TCodeViewer.MoveDown}

Procedure TCodeViewer.ScrollDraw;

Begin
  If CursorAt div 2 <> VScrollBar^.Value then
    Begin
      CursorAt := VScrollBar^.Value * 2;
      StartAt := CursorAt;
      Cursor.Y := 0;
      Delta.Y := VScrollBar^.Value;
      DrawView;
    End;
End;

Procedure TCodeViewer.MoveUp;

var
  AString : String;
  OldAdd : Word;
  i : Integer;

Begin
  Dec(Cursor.Y);
  OldAdd := CursorAt;
  Dec(CursorAt,6);
  Repeat
    Inc(CursorAt);
  Until ((OpCode(PZMem,CursorAt,AString)+CursorAt)=OldAdd) or
    (CursorAt=Pred(OldAdd));
  If Cursor.Y<0 then
    Begin
      Inc(Cursor.Y);
      StartAt := CursorAt;
      DrawView;
    End;
  SetCursor(0,Cursor.Y);
  VScrollBar^.SetValue(Integer(CursorAt div 2));
  Delta.Y := Integer(StartAt div 2);
End; {of TCodeViewer.MoveUp}

Procedure TCodeViewer.HandleEvent(var Event : TEvent);

Begin
  Inherited HandleEvent(Event);
  If Event.What = evKeyDown then
    Case Event.KeyCode of
      kbDown :
        Begin
          MoveDown;
          ClearEvent(Event);
        End;
      kbUp :
        Begin
          MoveUp;
          ClearEvent(Event);
        End;
      kbCtrlPgUp :
        Begin
          Cursor.Y := 0;
          StartAt := 0;
          CursorAt := 0;
          SetCursor(0,Cursor.Y);
          VScrollBar^.SetValue(0);
          DrawView;
          ClearEvent(Event);
        End;
      kbCtrlPgDn :
        Begin
          Cursor.Y := 0;
          StartAt := 0;
          CursorAt := 0;
          SetCursor(0,Cursor.Y);
          VScrollBar^.SetValue(0);
          DrawView;
          ClearEvent(Event);
        End;
      kbPgUp :
        Begin
          Cursor.Y := 0;
          StartAt := CursorAt-$20;
          CursorAt := StartAt;
          SetCursor(0,Cursor.Y);
          VScrollBar^.SetValue(Integer(StartAt div 2));
          DrawView;
          ClearEvent(Event);
        End;
      kbPgDn :
        Begin
          Cursor.Y := 0;
          StartAt := CursorAt + $20;
          CursorAt := StartAt;
          SetCursor(0,Cursor.Y);
          VScrollBar^.SetValue(Integer(StartAt div 2));
          DrawView;
          ClearEvent(Event);
        End;
    End;
  If Event.What = evCommand then
    Case Event.Command of
      cmChangedPC :
        Begin
          MoveToPC;
          ClearEvent(Event);
        End;
    End;
  If (Event.What = evMouseDown) and not (Event.Double) then
    If ChangedCursor(Event.Where) then
      ClearEvent(Event);
  If (Event.What = evMouseDown) and (Event.Double) then
    If ChangedPC(Event.Where) then
      ClearEvent(Event);
End; {of TCodeViewer.HandleEvent}

Function TCodeViewer.ChangedPC(GlobalPos : TPoint) : Boolean;

Var
  Pos : TPoint;
  i : Integer;
  AString : String;

Begin
  MakeLocal(GlobalPos,Pos);
  If MouseInView(GlobalPos) then
    Begin
      Cursor.Y := Pos.Y;
      CursorAt := StartAt;
      For i := 1 to Pos.Y do
        CursorAt := CursorAt + OpCode(PZMem,CursorAt,AString);
      SetCursor(0,Cursor.Y);
      VScrollBar^.SetValue(Integer(CursorAt div 2));
      Delta.Y := Integer(StartAt div 2);
      Engine^.IRegs.PC := CursorAt;
      Message(Owner^.Owner^.Owner,evCommand,cmRedrawAll,@Self);
    End;
End; {of TCodeViewer.MoveToPC}

Procedure TCodeViewer.ChangePC;

Begin
  Engine^.IRegs.PC := CursorAt;
  Message(Owner^.Owner^.Owner,evCommand,cmRedrawAll,@Self);
End; {of TCodeViewer.MoveToPC}

Function TCodeViewer.ChangedCursor(GlobalPos : TPoint) : Boolean;

Var
  Pos : TPoint;
  AString : String;
  i : Integer;

Begin
  MakeLocal(GlobalPos,Pos);
  If MouseInView(GlobalPos) then
    Begin
      Cursor.Y := Pos.Y;
      CursorAt := StartAt;
      For i := 1 to Pos.Y do
        CursorAt := CursorAt + OpCode(PZMem,CursorAt,AString);
      SetCursor(0,Cursor.Y);
      VScrollBar^.SetValue(Integer(CursorAt div 2));
      Delta.Y := Integer(StartAt div 2);
      DrawView;
    End;
End; {of TRegisterInput.ChangedCursor}

{************************************************************************}
{************************************************************************}

Constructor TRegisterInput.Init(var Bounds : TRect; ARegister : PWord);

Begin
  Inherited Init(Bounds);
  ShowCursor;
  Options := Options or ofFirstClick or ofSelectable;
  Register := ARegister;
End; {of TRegisterInput.Init}

Procedure TRegisterInput.Draw;

Var
  AString : String;

Begin
  FormatStr(AString,'%04x',Register^);
  WriteStr(0,0,AString,GetColor(19));
End; {of TRegisterInput.Draw}

Procedure TRegisterInput.MoveLeft;

Begin
  Dec(Cursor.X);
  If Cursor.X < 0 then
    Cursor.X := 0;
  SetCursor(Cursor.X,Cursor.Y);
End; {of TRegisterInput.MoveLeft}

Procedure TRegisterInput.MoveRight;

Begin
  Inc(Cursor.X);
  If Cursor.X >3 then
    Cursor.X := 3;
  SetCursor(Cursor.X,Cursor.Y);
End; {of TRegisterInput.MoveRight}

Procedure TRegisterInput.Enter(const AChar : Char);

Var
  Add, i : Word;

Begin
  Add := 1;
  For i := 1 to (3-Cursor.X) do
    Add := Add*16;
  Register^ := (Register^ and not (Add * $F)) + (Pos(AChar,HexDigits) - 1)
    * Add;
  MoveRight;
  DrawView;
  Message(Owner^.Owner^.Owner,evCommand,cmRedrawMemory,nil);
End; {of TRegisterInput.Enter}

Function TRegisterInput.ChangedCursor(GlobalPos : TPoint) : Boolean;

Var
  Pos : TPoint;

Begin
  MakeLocal(GlobalPos,Pos);
  If (Pos.X >=0 ) and (Pos.X < 4) and (Pos.Y=0) then
    Begin
       Cursor.X := Pos.X;
      DrawView;
    End;
End; {of TRegisterInput.ChangedCursor}

Procedure TRegisterInput.HandleEvent(var Event : TEvent);

Begin
  Inherited HandleEvent(Event);
  If Event.What = evKeyDown then
    Case Event.KeyCode of
      kbLeft,kbDel :
        Begin
          MoveLeft;
          ClearEvent(Event);
        End;
      kbRight :
        Begin
          MoveRight;
          ClearEvent(Event);
        End;
    End;
  If Event.What = evMouseDown then
    If ChangedCursor(Event.Where) then
      ClearEvent(Event);
  If (Event.What = evKeyDown) and (Upcase(Event.CharCode) in
    ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'])
      then
    Begin
      Enter(Upcase(Event.CharCode));
      Message(Owner^.Owner^.Owner, evCommand, cmRedrawAll, nil);
      ClearEvent(Event);
    End;
End; {of TRegisterInput.HandleEvent}

Constructor TFlagInput.Init(var Bounds : TRect; ARegister : PByte;
  AFlagMask : Byte);

Begin
  Inherited Init(Bounds);
  ShowCursor;
  Options := Options or ofFirstClick or ofSelectable;
  Register := ARegister;
  FlagMask := AFlagMask;
End; {of TFlagInput.Init}

Procedure TFlagInput.Draw;

Begin
  If (Register^ and FlagMask) = 0 then
    WriteStr(0,0,'0',GetColor(19)) else
    WriteStr(0,0,'1',GetColor(19));
End; {of TFlagInput.Draw}

Procedure TFlagInput.Enter(const AChar : Char);

Begin
  If AChar = '0' then
    Register^ := (Register^ and not FlagMask) else
    Register^ := (Register^ and not FlagMask) + FlagMask;
  DrawView;
End; {of TFlagInput.Enter}

Procedure TFlagInput.HandleEvent(var Event : TEvent);

Begin
  Inherited HandleEvent(Event);
  If Event.What = evKeyDown then
    Case Event.CharCode of
      '0','1' :
        Begin
          Enter(Event.CharCode);
          Message(Owner, evCommand, cmRedrawCode, nil);
          ClearEvent(Event);
        End;
    End;
  If (Event.What = evMouseDown) and (Event.Double) then
    Begin
      If (Register^ and FlagMask) = 0 then
        Enter('1') else
        Enter('0');
      Message(Owner, evCommand, cmRedrawCode, nil);
      ClearEvent(Event);
    End;
End;{of TFlagInput.HandleEvent}

Constructor TShowCode.Init(var Bounds : TRect; APC : PWord; AZMem :
  Pointer);

Begin
  Inherited Init(Bounds);
  PC := APC;
  PZMem := AZMem;
End; {of TShowCode.Init}

Procedure TShowCode.Draw;

Var
  Buf : TDrawBuffer;
  AString : String;

Begin
  AString := '';
  OpCode(PZMem,PC^,AString);
  AString := ' '+AString;
  While Length(AString)<17 do
    AString := AString+' ';
  MoveStr(Buf,AString,GetColor(19));
  WriteBuf(0,0,17,1,Buf);
End; {of TShowCode.Draw}

Procedure TRegistersDialog.Close;

Begin
  If Valid(cmClose) then
    Hide;
End;

Constructor TRegistersDialog.Init(AZMem : Pointer; Engine : PEngine);

Var
  PRegInput : PRegisterInput;
  PFlag : PFlagInput;
  R : TRect;

Begin
  R.Assign(0,0,19,12);
  Inherited Init(R,'Z80 CPU');
  Number := 2;

  R.Assign(5,1,9,2);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.ZRegs.AF));
  Insert(PRegInput);
  R.Assign(1,1,5,2);
  Insert(New(PLabel,Init(R,'af ',PRegInput)));

  R.Assign(13,1,17,2);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.ARegs.AF));
  Insert(PRegInput);
  R.Assign(9,1,13,2);
  Insert(New(PLabel,Init(R,'af''',PRegInput)));

  R.Assign(5,2,9,3);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.ZRegs.BC));
  Insert(PRegInput);
  R.Assign(1,2,5,3);
  Insert(New(PLabel,Init(R,'bc ',PRegInput)));

  R.Assign(13,2,17,3);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.ARegs.BC));
  Insert(PRegInput);
  R.Assign(9,2,13,3);
  Insert(New(PLabel,Init(R,'bc''',PRegInput)));

  R.Assign(5,3,9,4);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.ZRegs.DE));
  Insert(PRegInput);
  R.Assign(1,3,5,4);
  Insert(New(PLabel,Init(R,'de ',PRegInput)));

  R.Assign(13,3,17,4);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.ARegs.DE));
  Insert(PRegInput);
  R.Assign(9,3,13,4);
  Insert(New(PLabel,Init(R,'de''',PRegInput)));

  R.Assign(5,4,9,5);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.ZRegs.HL));
  Insert(PRegInput);
  R.Assign(1,4,5,5);
  Insert(New(PLabel,Init(R,'hl ',PRegInput)));

  R.Assign(13,4,17,5);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.ARegs.HL));
  Insert(PRegInput);
  R.Assign(9,4,13,5);
  Insert(New(PLabel,Init(R,'hl''',PRegInput)));

  R.Assign(5,5,9,6);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.IRegs.IX));
  Insert(PRegInput);
  R.Assign(1,5,5,6);
  Insert(New(PLabel,Init(R,'ix ',PRegInput)));

  R.Assign(13,5,17,6);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.IRegs.IY));
  Insert(PRegInput);
  R.Assign(9,5,13,6);
  Insert(New(PLabel,Init(R,'iy ',PRegInput)));

  R.Assign(5,6,9,7);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.IRegs.PC));
  Insert(PRegInput);
  R.Assign(1,6,5,7);
  Insert(New(PLabel,Init(R,'pc ',PRegInput)));

  R.Assign(13,6,17,7);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.IRegs.SP));
  Insert(PRegInput);
  R.Assign(9,6,13,7);
  Insert(New(PLabel,Init(R,'sp ',PRegInput)));

  R.Assign(4,7,5,8);
  PFlag := New(PFlagInput,Init(R,@Engine^.ZRegs.Flags,fSign));
  Insert(PFlag);
  R.Assign(1,7,4,8);
  Insert(New(PLabel,Init(R,'s ',PFlag)));

  R.Assign(8,7,9,8);
  PFlag := New(PFlagInput,Init(R,@Engine^.ZRegs.Flags,fZero));
  Insert(PFlag);
  R.Assign(5,7,8,8);
  Insert(New(PLabel,Init(R,'z ',PFlag)));

  R.Assign(12,7,13,8);
  PFlag := New(PFlagInput,Init(R,@Engine^.ZRegs.Flags,fHalf));
  Insert(PFlag);
  R.Assign(9,7,12,8);
  Insert(New(PLabel,Init(R,'h ',PFlag)));

  R.Assign(16,7,17,8);
  PFlag := New(PFlagInput,Init(R,@Engine^.ZRegs.Flags,fParity));
  Insert(PFlag);
  R.Assign(13,7,16,8);
  Insert(New(PLabel,Init(R,'v ',PFlag)));

  R.Assign(4,8,5,9);
  PFlag := New(PFlagInput,Init(R,@Engine^.ZRegs.Flags,fSub));
  Insert(PFlag);
  R.Assign(1,8,4,9);
  Insert(New(PLabel,Init(R,'n ',PFlag)));

  R.Assign(8,8,9,9);
  PFlag := New(PFlagInput,Init(R,@Engine^.ZRegs.Flags,fCarry));
  Insert(PFlag);
  R.Assign(5,8,8,9);
  Insert(New(PLabel,Init(R,'c ',PFlag)));

  R.Assign(13,8,17,9);
  PRegInput := New(PRegisterInput,Init(R,@Engine^.ORegs.R));
  Insert(PRegInput);
  R.Assign(9,8,13,9);
  Insert(New(PLabel,Init(R,'ir ',PRegInput)));

  R.Assign(7,9,8,10);
  PFlag := New(PFlagInput,Init(R,@Engine^.ORegs.IFF1,255));
  Insert(PFlag);
  R.Assign(1,9,7,10);
  Insert(New(PLabel,Init(R,'iff1 ',PFlag)));

  R.Assign(16,9,17,10);
  PFlag := New(PFlagInput,Init(R,@Engine^.ORegs.IFF2,255));
  Insert(PFlag);
  R.Assign(10,9,16,10);
  Insert(New(PLabel,Init(R,'iff2 ',PFlag)));

  R.Assign(1,10,18,11);
  Insert(New(PShowCode,Init(R,@Engine^.IRegs.PC,Engine^.PZMem)));

  SelectNext(False);
End; {of TRegistersDialog.Init}

Procedure TRegistersDialog.HandleEvent(var Event : TEvent);

Begin
  Inherited HandleEvent(Event);
  If (Event.What = evCommand) and (Event.Command = cmRedrawCode) then
    Begin
      ReDraw;
      ClearEvent(Event);
    End;
End; {of TRegistersDialog.HandleEvent}

End. {of Unit ZRegDlg}
