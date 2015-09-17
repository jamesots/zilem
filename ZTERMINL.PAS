Unit ZTerminl;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#      Terminal Emulator       #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Uses
  Objects, Drivers, App, Menus, Crt,
  ZGlobals, ZConsts;

Type
  PScreen = ^TScreen;
  TScreen = Array[1..25,1..80] of Word;

  PZTerminal = ^TZTerminal;
  TZTerminal = object(TObject)
    Mode : Integer;
    TempScreenMode : Word;
    TheDesktop : PDesktop;
    TheMenuBar : PMenuView;
    TheStatusLine : PStatusLine;
    Screen : PScreen;
    Status : Word;
    TempScreen : PScreen;
    Attrib : Integer;
    Terminal : Record
      Width : Integer;
      Height : Integer;
      Wrap : Boolean;
      Scroll : Boolean;
      ScrollViewport : Boolean;
    End;
    Pos : Record
      Y,X : Integer;
    End;
    Viewport : Record
      A,B : Record
        X,Y : Integer;
      End;
    End;
    Constructor Init(ADesktop : PDesktop; AMenuBar : PMenuView;
      AStatusLine : PStatusLine);
    Destructor Done; virtual;
    Procedure Z80Screen;
    Procedure ZiLEMScreen;
    Procedure PrintChar(AChar : Char);
    Procedure Scroll(Line : Integer);
    Procedure UpdateCursor;
    Procedure ClearViewport;
    Procedure HomeCursor;
    Procedure CursorUp;
    Procedure CursorDown;
    Procedure CursorLeft;
    Procedure CursorRight;
    Procedure Control(AByte : Byte);
    Function ReadChar : Char;
    Procedure ShowCursor;
    Procedure HideCursor;
    Function KeyStatus : Boolean;
  End;

Implementation

Procedure TZTerminal.ShowCursor;

Begin
  InLine($B4/$01/$B9/$07/$06/$CD/$10);
End; {of TZTerminal.ShowCursor}

Procedure TZTerminal.HideCursor;

Begin
  InLine($B4/$01/$B9/$20/$21/$CD/$10);
End; {of TZTerminal.HideCursor}

Procedure TZTerminal.UpdateCursor;

Begin
  GotoXY(Pos.X+Pred(Viewport.A.X),Pos.Y+Pred(ViewPort.A.Y));
End; {of TZTerminal.UpdateCursor}

Procedure TZTerminal.CursorUp;

Begin
  Dec(Pos.Y);
  If Pos.Y<1 then
    Pos.Y:=1;
  UpdateCursor;
End; {of TZTerminal.CursorUp}

Procedure TZTerminal.CursorDown;

Begin
  Inc(Pos.Y);
  If Pos.Y>Terminal.Height then
    Pos.Y := Terminal.Height;
  UpdateCursor;
End; {of TZTerminal.CursorDown}

Procedure TZTerminal.CursorLeft;

Begin
  Dec(Pos.X);
  If Pos.X<1 then
    If Pos.Y>1 then
       Begin
         Pos.X := Terminal.Width;
         Dec(Pos.Y);
       End else
       Inc(Pos.X);
  UpdateCursor;
End; {of TZTerminal.CursorLeft}

Procedure TZTerminal.CursorRight;

Begin
  Inc(Pos.X);
  If Pos.X>Terminal.Width then
    If Pos.Y<Terminal.Height then
      Begin
        Pos.X := 1;
        Inc(Pos.Y);
      End else
      Dec(Pos.X);
  UpdateCursor;
End; {of TZTerminal.Cursor.Right}

Function TZTerminal.KeyStatus : Boolean;

Begin
  KeyStatus := KeyPressed;
End; {of TZTerminal.KeyStatus}

Function TZTerminal.ReadChar : Char;

Begin
  ReadChar := ReadKey;
End; {of TZTerminal.ReadChar}

Procedure TZTerminal.Control(AByte : Byte);

Begin
  Case Status of
    teOk :
      Case Char(AByte) of
        #$1B : Status := teEscape;
        #$07 : Write(#7);
        #$08 : CursorLeft;
        #$0D : 
          Begin
            Pos.X := 1;
            UpdateCursor;
          End;
        #$0A : Begin
                  CursorDown;
                  If Pos.Y = Terminal.Height then
                    Scroll(Terminal.Height);
                End;
      Else
        PrintChar(Char(AByte));
      End;
    tePositionColumn :
      Begin
        Pos.X := AByte-32;
        If Pos.X>Terminal.Width then
          Pos.X := Terminal.Width;
        If Pos.X<1 then
          Pos.X := 1;
        UpdateCursor;
        Status := teOk;
      End;
    tePositionRow :
      Begin
        Pos.Y := AByte-32;
        If Pos.Y>Terminal.Height then
          Pos.Y := Terminal.Height;
        If Pos.Y<1 then
          Pos.Y := 1;
        Status := tePositionColumn;
      End;
    teEscape :
      Case Char(AByte) of
        'A' :
          Begin
            CursorUp;
            Status := teOk;
          End;
        'B' :
          Begin
            CursorDown;
            Status := teOk;
          End;
        'C' :
          Begin
            CursorRight;
            Status := teOk;
          End;
        'D' :
          Begin
            CursorLeft;
            Status := teOk;
          End;
        'E' :
          Begin
            ClearViewport;
            Status := teOk;
          End;
        'H' :
          Begin
            HomeCursor;
            Status := teOk;
          End;
        'Y' :
          Status := tePositionRow;
        'v' :
          Begin
            Terminal.Wrap := True;
            Status := teOk;
          End;
        'w' :
          Begin
            Terminal.Wrap := False;
            Status := teOk;
          End;
        'f' :
          Begin
            HideCursor;
            Status := teOk;
          End;
        'e' :
          Begin
            ShowCursor;
            Status := teOk;
          End;
        'p' :
          Begin
            Attrib := $70;
            Status := teOk;
          End;
        'q' :
          Begin
            Attrib := $07;
            Status := teOk;
          End;
      Else
        Status := teOk;
      End;
  Else
      Status := teOk;
  End;
End; {of TZTerminal.Control}

Procedure TZTerminal.ClearViewport;

Var
  XX : Integer;
  YY : Integer;

Begin
  For YY := Viewport.A.Y to Viewport.B.Y do
    If Terminal.ScrollViewport then
      For XX := Viewport.A.X to Viewport.B.X do
        Screen^[YY,XX] := Word(256*Attrib+32) else
      For XX := 1 to Terminal.Width do
        Screen^[YY,XX] := Word(256*Attrib+32);
End; {of TZTerminal.ClearViewport}

Procedure TZTerminal.HomeCursor;

Begin
  Pos.X := 1;
  Pos.Y := 1;
  UpdateCursor;
End; {of TZTerminal.HomeCursor}

Procedure TZTerminal.Scroll(Line : Integer);

Var
  XX : Integer;
  YY : Integer;

Begin
  With Terminal do
    Begin
      If Line>Height then
        Line := Height;
      For YY := Succ(Viewport.A.Y) to Viewport.A.Y+Pred(Line) do
        If Terminal.ScrollViewport then
          For XX := Viewport.A.X to Viewport.B.X do
            Screen^[Pred(XX),XX] := Screen^[YY,XX] else
          For XX := 0 to Width do
            Screen^[Pred(YY),XX] := Screen^[YY,XX];
      For XX := 0 to Width do
        Screen^[Viewport.A.Y+Pred(Line),XX] := Attrib*256+32;
    End;
End; {of TZTerminal.Scroll}

Procedure TZTerminal.PrintChar(AChar : Char);

Var
  Swapped : Boolean;

Begin
  If Mode=tmZiLEM then
    Begin
      Z80Screen;
      Mode := tmZ80;
      Swapped := True;
    End else
    Swapped := False;
  With Terminal, Pos do
    Begin
      Screen^[Y+Pred(Viewport.A.Y),X+Pred(Viewport.A.X)] := Byte(AChar)+
        256*Attrib;
      Inc(X);
      If X > (Viewport.B.X-Pred(Viewport.A.X)) then
        If Wrap then
          Begin
            X := 1;
            Inc(Y);
            If Y > (Viewport.B.Y-Pred(Viewport.A.Y)) then
              Begin
                If Scroll then
                  TZTerminal.Scroll(Viewport.B.Y-Pred(Viewport.A.Y));
                Y := Viewport.B.Y-Pred(Viewport.A.Y);
              End;
          End else
          X := Viewport.B.X-Pred(Viewport.A.X);
      UpdateCursor;
    End;
  If Swapped then
    Begin
      ZiLEMScreen;
      Mode := tmZiLEM;
    End;
End; {of TZTerminal.PrintChar}

Destructor TZTerminal.Done;

Begin
  Dispose(TempScreen);
End; {of TZTerminal.Done}

Constructor TZTerminal.Init(ADesktop : PDesktop ; AMenuBar : PMenuView;
  AStatusLine : PStatusLine);

Var
  x,y : Integer;

Begin
  TheDesktop := ADesktop;
  TheMenuBar := AMenuBar;
  TheStatusLine := AStatusLine;
  New(Screen);
  Screen := Ptr($B800,0000);
  New(TempScreen);
  Attrib := $07;
  For y := 1 to 25 do
    For x := 1 to 80 do
      TempScreen^[y,x] := Word(Attrib*256+32);
  Pos.X := 1;
  Pos.Y := 1;
  Mode := tmZiLEM;
  With Terminal do
    Begin
      Width := 80;
      Height := 24;
      Wrap := True;
      Scroll := True;
      ScrollViewport := False;
    End;
  With Viewport do
    Begin
      A.X := 1;
      A.Y := 1;
      B.X := Terminal.Width;
      B.Y := Terminal.Height;
    End;
End; {of TZTerminal.Init}

Procedure TZTerminal.ZiLEMScreen;

Begin
  HideCursor;
  TempScreen^ := Screen^;
  SetVideoMode(TempScreenMode);
  InitEvents;
  TheDesktop^.Redraw;
  TheMenuBar^.Draw;
  TheStatusLine^.Draw;
  Mode := tmZiLEM;
End; {of TZTerminal.ZiLEMScreen}

Procedure TZTerminal.Z80Screen;

Begin
  DoneEvents;
  TempScreenMode := ScreenMode;
  SetVideoMode(ScreenMode and not smFont8x8);
  Screen^ := TempScreen^;
  ShowCursor;
  UpdateCursor;
  Mode := tmZ80;
End; {of TZTerminal.Z80Screen}

End. {of Unit ZTerminl}
