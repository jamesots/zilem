Unit ZHex;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#    Hex/ASCII dump window     #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Uses
  Objects, Views, ZConsts, Drivers, ZGlobals;

Type
  PInteger = ^Integer;

  PHexViewer = ^THexViewer;
  THexViewer = Object(TScroller)
    PZMem : Pointer;
    UseHexView : Boolean;
    CurrentPos : Integer;
    Constructor Init(var Bounds : TRect; AVScroller : PScrollBar;
      CPZMem : Pointer);
    Procedure Draw; virtual;
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure UpdateCursor;
    Procedure MoveUp;
    Procedure MoveDown;
    Procedure MoveLeft;
    Procedure MoveRight;
    Procedure MovePgDn;
    Procedure MovePgUp;
    Procedure MoveCtrlPgDn;
    Procedure MoveCtrlPgUp;
    Procedure MoveCtrlRight;
    Procedure MoveCtrlLeft;
    Procedure MoveHome;
    Procedure MoveEnd;
    Procedure ScrollDraw; virtual;
    Function ChangedAddress(GlobalPos : TPoint) : Boolean;
    Procedure HexChangeMemory(HexByte : Char);
    Procedure AsciiChangeMemory(AsciiByte : Char);
    Procedure DrawByte(const Address : Word);
  End;

  PAddressDisplay = ^TAddressDisplay;
  TAddressDisplay = Object(TView)
    CurrentPos : PInteger;
    Constructor Init(ACurrentPos : PInteger);
    Procedure Draw; virtual;
  End;

  PHexWindow = ^THexWindow;
  THexWindow = Object(TWindow)
    Interior : PHexViewer;
    AddressDisplay : PAddressDisplay;
    Constructor Init(var Bounds : TRect; CPZMem : Pointer);
    Procedure SizeLimits(var Min, Max: TPoint); virtual;
    Procedure Close; virtual;
    Procedure HandleEvent(var Event : TEvent); virtual;
  End;

Procedure AddHexSpace(const decimal : byte; var S : String);

Implementation

Constructor TAddressDisplay.Init(ACurrentPos : PInteger);

Var
  R1,R2 : TRect;

Begin
  Owner^.GetBounds(R1);
  Options := Options and not ofSelectable;
  GrowMode := gfGrowLoX;
  R2.Assign(R1.A.X+2,R1.B.Y-1,R1.A.X+9,R1.B.Y);
  Inherited Init(R2);
  CurrentPos := ACurrentPos;
End;

Procedure TAddressDisplay.Draw;

Var
  DrawBuf : TDrawBuffer;
  S : String;
  Param : Longint;
  Colour : Word;

Begin
  Param := Longint(CurrentPos^);
  If Pref.Base = 0 then
    FormatStr(S,' $%04x ',Param) else
    FormatStr(S,' %d ออออ',Param);
  S[0] := #7;
  Colour := GetColor(1);
  MoveStr(DrawBuf,S,Colour);
  WriteLine(0,0,7,1,DrawBuf);
End;

Procedure THexWindow.HandleEvent(var Event : TEvent);

Begin
  Inherited HandleEvent(Event);
End;

Procedure THexWindow.Close;

Begin
  If Valid(cmClose) then
    Hide;
End;

Procedure THexViewer.HexChangeMemory(HexByte : Char);

Begin
  HexByte := UpCase(HexByte);
  Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+CurrentAddress))^) :=
    (Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+CurrentAddress))^) and
    (15+(CurrentPos*225))) + ((Pos(HexByte,HexDigits)-1) *
    ((1-CurrentPos)*15+1));
  DrawByte(CurrentAddress);
  MoveRight;
End; {of THexViewer.HexChangeMemory}

Procedure THexViewer.AsciiChangeMemory(AsciiByte : Char);

Begin
  Char((Ptr(Seg(PZMem^),Ofs(PZMem^)+CurrentAddress))^) :=
    AsciiByte;
  DrawByte(CurrentAddress);
  MoveRight;
End; {of THexViewer.AsciiChangeMemory}

Function THexViewer.ChangedAddress(GlobalPos : TPoint) : Boolean;

Var
  Pos : TPoint;

Begin
  MakeLocal(GlobalPos,Pos);
  If (Pos.X > 6) and (Pos.X < 55) and (((Pos.X-7) mod 3) <> 2) then
    Begin
      CurrentAddress := (Word(Pos.Y)+Word(Delta.Y))*16 +
        (Word(Pos.X)-7) div 3;
      CurrentPos := (Pos.X-7) mod 3;
      UseHexView := True;
      UpdateCursor;
      ChangedAddress := True;
    End else
  If (Pos.X > 55) and (Pos.X < 72) then
    Begin
      CurrentAddress := (Word(Pos.Y)+Word(Delta.Y))*16 + (Word(Pos.X)-56);
      CurrentPos := 0;
      UseHexView := False;
      UpdateCursor;
      ChangedAddress := True;
    End else
      ChangedAddress := False;
End; {of THexViewer.ChangedAddress}

Procedure THexViewer.ScrollDraw;

Begin
  Inherited ScrollDraw;
  If (CurrentAddress<Word(Delta.Y)*16) then
    Begin
      CurrentAddress := Word(Delta.Y)*16 + CurrentAddress mod 16;
      CurrentPos := 0;
      UpdateCursor;
    End else
    If (CurrentAddress>(Word(Delta.Y)+Word(Size.Y))*16-1) then
      Begin
        CurrentAddress := (Word(Delta.Y)+Word(Size.Y)-1)*16 +
          CurrentAddress mod 16;
        UpdateCursor;
      End;
End; {of THexViewer.ScrollDraw}

Procedure THexViewer.HandleEvent(var Event : TEvent);

Begin
  Inherited HandleEvent(Event);
  If Event.What = evKeyDown then
    Case Event.KeyCode of
      kbUp :
        Begin
          MoveUp;
          ClearEvent(Event);
        End;
      kbDown :
        Begin
          MoveDown;
          ClearEvent(Event);
        End;
      kbLeft, kbBack :
        Begin
          MoveLeft;
          ClearEvent(Event);
        End;
      kbRight :
        Begin
          MoveRight;
          ClearEvent(Event);
        End;
      kbPgDn :
        Begin
          MovePgDn;
          ClearEvent(Event);
        End;
      kbPgUp :
        Begin
          MovePgUp;
          ClearEvent(Event);
        End;
      kbCtrlPgDn :
        Begin
          MoveCtrlPgDn;
          ClearEvent(Event);
        End;
      kbCtrlPgUp :
        Begin
          MoveCtrlPgUp;
          ClearEvent(Event);
        End;
      kbCtrlRight :
        Begin
          MoveCtrlRight;
          ClearEvent(Event);
        End;
      kbCtrlLeft :
        Begin
          MoveCtrlLeft;
          ClearEvent(Event);
        End;
      kbTab :
        Begin
          UseHexView := Not UseHexView;
          CurrentPos := 0;
          UpdateCursor;
          ClearEvent(Event);
        End;
      kbEnd :
        Begin
          MoveEnd;
          ClearEvent(Event);
        End;
      kbHome :
        Begin
          MoveHome;
          ClearEvent(Event);
        End;
    else
      If (((Event.CharCode>#$2F) and (Event.CharCode<#$40)) or
        ((Upcase(Event.CharCode)>#$40) and (Upcase(Event.CharCode)<#$47)))
        and UseHexView then
        Begin
           HexChangeMemory(Event.CharCode);
          ClearEvent(Event);
        End else
        If not UseHexView then
          Begin
            AsciiChangeMemory(Event.CharCode);
            ClearEvent(Event);
          End;
    End;
  If Event.What = evCommand then
    case Event.Command of
      cmUpdateMemoryPos :
        Begin
          UpdateCursor;
          ClearEvent(Event);
        End;
      cmRedrawMemory :
        Begin
          DrawView;
          ClearEvent(Event);
        End;
    End;
  If Event.What = evMouseDown then
     If ChangedAddress(Event.Where) then
       ClearEvent(Event);
End; {of THexViewer.HandleEvent}

Procedure THexViewer.UpdateCursor;

Begin
  If (CurrentAddress < Word(Delta.Y)*16) then
    Begin
      HideCursor;
      ScrollTo(0,CurrentAddress div 16);
      ShowCursor;
    End;
  If (CurrentAddress > (Word(Delta.Y)+Word(Size.Y)-1)*16) then
    Begin
      HideCursor;
      ScrollTo(0,CurrentAddress div 16 - Size.Y + 1);
      ShowCursor;
    End;
  If UseHexView then
    SetCursor((CurrentAddress-Word(Delta.Y)*16) mod 16 * 3 + 7 +
      CurrentPos,(CurrentAddress-Word(Delta.Y)*16) div 16) else
    SetCursor((CurrentAddress-Word(Delta.Y)*16) mod 16 + 56,
      (CurrentAddress-Word(Delta.Y)*16) div 16);
End; {of THexViewer.UpdateCursor}

Procedure THexViewer.MoveHome;

Begin
  CurrentAddress := CurrentAddress div 16 * 16;
  CurrentPos := 0;
  UpdateCursor;
End; {of THexViewer.MoveHome}

Procedure THexViewer.MoveEnd;

Begin
  CurrentAddress := CurrentAddress div 16 * 16 + 15;
  CurrentPos := 0;
  UpdateCursor;
End; {of THexViewer.MoveEnd}

Procedure THexViewer.MoveCtrlRight;

Begin
  If CurrentAddress<MemorySize then
    Begin
      Inc(CurrentAddress);
      CurrentPos := 0;
    End;
  UpdateCursor;
End; {of THexViewer.MoveCtrlRight}

Procedure THexViewer.MoveCtrlLeft;

Begin
  If (CurrentAddress>0) or ((CurrentAddress=0) and (CurrentPos=1)) then
    If CurrentPos = 0 then
      Dec(CurrentAddress) else
      CurrentPos := 0;
  UpdateCursor;
End; {of THexViewer.MoveCtrlLeft}

Procedure THexViewer.MoveUp;

Begin
  If CurrentAddress>15 then
    CurrentAddress := CurrentAddress - 16;
  UpdateCursor;
End; {of THexViewer.MoveUp}

Procedure THexViewer.MoveDown;

Begin
  If CurrentAddress < (MemorySize-$F) then
    CurrentAddress := CurrentAddress + 16;
  UpdateCursor;
End; {of THexViewer.MoveDown}

Procedure THexViewer.MoveLeft;

Begin
  If (CurrentAddress>0) or ((CurrentAddress=0) and (CurrentPos=1)) then
    If UseHexView then
      Begin
        Dec(CurrentPos);
        If CurrentPos<0 then
          Begin
            Dec(CurrentAddress);
            CurrentPos := 1;
          End;
      End else
      Dec(CurrentAddress);
  UpdateCursor;
End; {of THexViewer.MoveLeft}

Procedure THexViewer.MoveRight;

Begin
  If (CurrentAddress<MemorySize) or ((CurrentAddress = MemorySize) and
    (CurrentPos = 0) and UseHexView) then
    If UseHexView then
      Begin
        Inc(CurrentPos);
        If CurrentPos=2 then
          Begin
            Inc(CurrentAddress);
            CurrentPos := 0;
          End;
      End else
      Inc(CurrentAddress);
  UpdateCursor;
End; {of THexViewer.MoveRight}

Procedure THexViewer.MovePgDn;

Begin
  If (MemorySize-CurrentAddress)>(Size.Y-1)*16 then
    CurrentAddress := CurrentAddress+(Size.Y-1)*16 else
    Begin
      CurrentAddress := MemorySize;
      CurrentPos := 0;
    End;
  UpdateCursor;
End; {of THexViewer.MovePgDn}

Procedure THexViewer.MovePgUp;

Begin
  If (Size.Y-1)*16 < CurrentAddress then
    CurrentAddress := CurrentAddress-(Size.Y-1)*16 else
    Begin
      CurrentAddress := 0;
      CurrentPos := 0;
    End;
  UpdateCursor;
End; {of THexViewer.MovePgUp}

Procedure THexViewer.MoveCtrlPgDn;

Begin
  CurrentAddress := MemorySize;
  CurrentPos := 0;
  UpdateCursor;
End; {of THexViewer.MoveCtrlPgDn}

Procedure THexViewer.MoveCtrlPgUp;

Begin
  CurrentAddress := 0;
  CurrentPos := 0;
  UpdateCursor;
End; {of THexViewer.MoveCtrlPgUp}

Procedure THexWindow.SizeLimits(var Min, Max: TPoint);

Begin
  Inherited SizeLimits(Min, Max);
  Max.X := 75;
  Min.X := 75;
End; {of THexWindow.SizeLimits}

Constructor THexWindow.Init(var Bounds : TRect; CPZMem : Pointer);

Var
  R : TRect;
  ScrollBar : PScrollBar;

Begin
  Inherited Init(Bounds,'Z80 Memory',1);
  ScrollBar := StandardScrollBar(sbVertical);
  Insert(ScrollBar);
  GetExtent(R);
  R.Grow(-1,-1);
  Interior := New(PHexViewer,Init(R,ScrollBar,CPZMem));
  Insert(Interior);
  AddressDisplay := New(PAddressDisplay,Init(@Interior^.CurrentPos));
  InsertBefore(Interior,Frame);
End; {of THexWindow.Init}

Constructor THexViewer.Init(var Bounds : TRect; AVScroller : PScrollBar;
  CPZMem : Pointer);

Begin
  Inherited Init(Bounds,nil,AVScroller);
  GrowMode := gfGrowHiX + gfGrowHiY;
  Options := Options or ofTileable;
  PZMem := CPZMem;
  SetLimit(0,MemorySize div 16 + 1);
  Cursor.X := 7;
  Cursor.Y := 0;
  ShowCursor;
  UseHexView := True;
End; {of THexViewer.Init}

Procedure AddHexSpace(const decimal : byte; var S : String);

{This is much faster than FormatStr}

Const
  HexDigits : string[16] = '0123456789ABCDEF';

Begin
  S := S + HexDigits[decimal div 16 + 1] + HexDigits[decimal mod 16 + 1]
    + ' ';
End; {of AddHexSpace}

Procedure THexViewer.DrawByte(const Address : Word);

Var
  B : Byte;
  S : String;
  X,Y : Integer;
  Buf : TDrawBuffer;

Begin
  B := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Address))^);
  S := '';
  AddHexSpace(B,S);
  X := CurrentAddress mod 16 * 3 + 7;
  Y := CurrentAddress div 16 - Delta.Y;
  MoveStr(Buf,S,GetColor(1));
  WriteLine(X,Y,3,1,Buf);
  X := CurrentAddress mod 16 + 56;
  If ((Pref.Prefs and 1) = 0) and (B<32) then
    B := Ord('.');
  If B = 0 then
    B := 32;
  MoveChar(Buf,Char(B),GetColor(1),1);
  WriteLine(X,Y,1,1,Buf);
End; {of THexViewer.DrawByte}

Procedure THexViewer.Draw;

Var
  DrawBuf : TDrawBuffer;
  Colour : Word;
  X,Y : Word;
  S,T : String;
  i : Word;
  B : Byte;
  C : Char;

Begin
  For Y := 0 to Size.Y-1 do
    Begin
      I := Y*16+Delta.Y*16;
      If I<MemorySize then
        Begin
          FormatStr(S,'%04x',I);  {Draw the address}
          S := ' '+S+': ';
          For X := I to I+15 do
            Begin
              B := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+X))^);{It crashes if}
              AddHexSpace(B,S);          {these are combined in one line.}
            End;
          S := S+' ';
          For X := I to I+15 do
            Begin
              C := Char((Ptr(Seg(PZMem^),Ofs(PZmem^)+X))^);
              If ((Pref.Prefs and 1) = 0) and (C<#32) then
                C := '.';
              S := S+C;
            End;
          S := S+' ';
          MoveStr(DrawBuf,S,GetColor(1));
        End else
          Begin
            FillChar(S,72,#32);
            Colour := GetColor(1);
            MoveStr(DrawBuf,S,Colour);
          End;
      WriteLine(0,Y,73,1,DrawBuf);
    End;
End; {of THexViewer.Draw}

End. {of Unit ZHex}
