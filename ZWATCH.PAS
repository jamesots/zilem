Unit ZWatch;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#           Watches            #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Uses
  App, Objects, Views, Drivers, Dialogs, ZEngine, ZGlobals, ZHex, ZConsts,
  ZInputs;

Type
  PInsertWatchDialog = ^TInsertWatchDialog;
  TInsertWatchDialog = Object(TDialog)
    PKindInputLine : PAddressInputLine;
    PKindRadio : PRadioButtons;
    Constructor Init;
  End;

  PWatchItem = ^TWatchItem;
  TWatchItem = Object(TObject)
    Kind : Integer;
    Address : Word;
    Register : ^Word;
    RegName : String[2];
  End;

  PWatchViewer = ^TWatchViewer;
  TWatchViewer = Object(TScroller)
    PZMem : Pointer;
    Engine : PEngine;
    Watches : PCollection;
    Constructor Init(var Bounds : TRect; AVScroller : PScrollBar;
      CPZMem : Pointer; AnEngine : PEngine);
    Procedure Draw; virtual;
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure MoveUp;
    Procedure MoveDown;
    Procedure AddWatch;
    Procedure RemoveWatch;
    Procedure ScrollDraw; virtual;
    Procedure ChangeBounds(Var Bounds : TRect); virtual;
    Function ChangedCursor(GlobalPos : TPoint) : Boolean;
  End;

  PWatchWindow = ^TWatchWindow;
  TWatchWindow = Object(TWindow)
    Interior : PWatchViewer;
    Constructor Init(var Bounds : TRect; CPZMem : Pointer;
      AnEngine : PEngine);
    Procedure SizeLimits(var Min, Max : TPoint); virtual;
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure Close; virtual;
  End;

Implementation

Procedure TWatchWindow.Close;

Var
  R : TRect;

Begin
  If Valid(cmClose) then
    Begin
      While Interior^.Watches^.Count > 0 do
        Interior^.RemoveWatch;
      Hide;
      R.A.X := 0;
      R.A.Y := Owner^.Size.Y - Owner^.Size.Y div 4 - 1;
      R.B.X := 75;
      R.B.Y := Owner^.Size.Y;
      ChangeBounds(R);
    End;
End;

Constructor TInsertWatchDialog.Init;

Var
  R : TRect;
  PKindButton : PButton;

Begin
  R.Assign(0,0,34,14);
  Inherited Init(R,'Add Watch');
  Options := Options or ofCentered;

  R.Assign(3,3,13,4);
  PKindInputLine := New(PAddressInputLine,Init(R,hcKindInputLine));
  Insert(PKindInputLine);
  R.Assign(2,2,10,3);
  Insert(New(PLabel,Init(R,'Add~r~ess',PKindInputLine)));

  R.Assign(3,6,31,10);
  PKindRadio := New(PRadioButtons, Init(R,
    NewSItem('~A~ddress',
    NewSItem('~B~C',
    NewSItem('~D~E',
    NewSItem('~H~L',
    NewSItem('I~X~',
    NewSItem('I~Y~',
    NewSItem('~S~P',
    NewSItem('~P~C',
    nil))))))))
  ));
  PKindRadio^.HelpCtx := hcKindRadio;
  Insert(PKindRadio);
  R.Assign(2,5,13,6);
  Insert(New(PLabel,Init(R,'Watch type',PKindRadio)));

  R.Assign(10,11,20,13);
  PKindButton := New(PButton,Init(R,'O~k~',cmOk,bfDefault));
  PKindButton^.HelpCtx := hcOkButton;
  Insert(PKindButton);

  R.Assign(21,11,31,13);
  PKindButton := New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal));
  PKindButton^.HelpCtx := hcCancelButton;
  Insert(PKindButton);

  SelectNext(False);
End; {of TInsertWatchDialog.Init}

Procedure TWatchWindow.SizeLimits(var Min, Max: TPoint);

Begin
  Inherited SizeLimits(Min, Max);
  Max.X := 75;
  Min.X := 75;
End; {of TWatchWindow.SizeLimits}

Constructor TWatchWindow.Init(var Bounds : TRect; CPZMem : Pointer;
  AnEngine : PEngine);

Var
  R : TRect;
  ScrollBar : PScrollBar;

Begin
  Bounds.B.X := Bounds.A.X+75;
  Inherited Init(Bounds,'Watches',4);
  HelpCtx := hcWatchWindow;
  ScrollBar := StandardScrollBar(sbVertical);
  Insert(ScrollBar);
  GetExtent(R);
  R.Grow(-1,-1);
  Interior := New(PWatchViewer, Init(R,ScrollBar,CPZMem,AnEngine));
  Insert(Interior);
End; {of TWatchWindow.Init}

Constructor TWatchViewer.Init(var Bounds : TRect; AVScroller : PScrollBar;
  CPZMem : Pointer; AnEngine : PEngine);

Begin
  Inherited Init(Bounds,nil,AVScroller);
  GrowMode := gfGrowHiX + gfGrowHiY;
  PZMem := CPZMem;
  Engine := AnEngine;
  SetLimit(0,0);
  Cursor.X := 0;
  Cursor.Y := 0;
  Watches := New(PCollection,Init(40,20));
End; {of TWatchViewer.Init}

Procedure TWatchViewer.Draw;

Var
  DrawBuf : TDrawBuffer;
  APtr : Pointer;
  Colour : Word;
  X,Y : Word;
  S,T : String;
  i : Word;
  B : Byte;
  C : Char;
  Z : Word;

Begin
  For Y := 0 to Size.Y do
    Begin
      If Cursor.Y = Y then
        Colour := GetColor(2) else
        Colour := GetColor(1);
      If (Y+Delta.Y) < Watches^.Count then
        Begin
          APtr := Watches^.At(Y+Delta.Y);
          If PWatchItem(APtr)^.Kind = wtAddress then
            I := PWatchItem(APtr)^.Address else
            I := PWatchItem(APtr)^.Register^;
          If PWatchItem(APtr)^.Kind = wtAddress then
            Begin
              FormatStr(S,'%04x',I);  {Draw the address}
              S := ' '+S+': ';
            End else
            S := '   '+PWatchItem(APtr)^.RegName+': ';
          X := I;
          For Z := 1 to 16 do
            Begin
              B := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+X))^);{It crashes if}
              AddHexSpace(B,S);          {these are combined in one line.}
              Inc(X);
            End;
          S := S+' ';
          X := I;
          For Z := 1 to 16 do
            Begin
              C := Char((Ptr(Seg(PZMem^),Ofs(PZmem^)+X))^);
              If ((Pref.Prefs and 1) = 0) and (C<#32) then
                C := '.';
              S := S+C;
              Inc(X);
            End;
          S := S+' ';
          MoveStr(DrawBuf,S,Colour);
        End else
          Begin
            FillChar(S,74,#32);
            S[0] := #73;
            MoveStr(DrawBuf,S,Colour);
          End;
      WriteLine(0,Y,73,1,DrawBuf);
    End;
End; {of TWatchViewer.Draw}

Procedure TWatchViewer.MoveUp;

Begin
  Dec(Cursor.Y);
  If Cursor.Y<0 then
    Begin
      Cursor.Y := 0;
      Dec(Delta.Y);
      If Delta.Y<0 then
        Delta.Y := 0 else
    End;
  VScrollBar^.SetValue(Cursor.Y+Delta.Y);
End; {of TWatchViewer.MoveUp}

Procedure TWatchViewer.MoveDown;

Begin
  Inc(Cursor.Y);
  If Cursor.Y>(Watches^.Count-Delta.Y) then
    Dec(Cursor.Y) else
    If Cursor.Y>=Size.Y then
      Begin
        Cursor.Y := Pred(Size.Y);
        Inc(Delta.Y);
        If Delta.Y > Limit.Y then
          Delta.Y := Limit.Y else
      End;
  VScrollBar^.SetValue(Cursor.Y+Delta.Y);
End; {of TWatchViewer.MoveDown}

Procedure TWatchViewer.RemoveWatch;

Begin
  If (Cursor.Y + Delta.Y) < Watches^.Count then
    Begin
      Watches^.Free(Watches^.At(Cursor.Y+Delta.Y));
      If Watches^.Count>=Pred(Size.Y) then
        Begin
          Dec(Limit.Y);
          SetLimit(Limit.X,Limit.Y);
        End;
      SetLimit(Limit.X,Limit.Y);
      VScrollBar^.SetRange(0,Watches^.Count);
      DrawView;
    End;
End; {of TWatchViewer.RemoveWatch}

Procedure TWatchViewer.AddWatch;

Const
  RegNames : Array[2..8] of String [2] =
    ('BC','DE','HL','IX','IY','SP','PC');

Var
  WatchInfo : Record
    Address : Word;
    Kind : Integer;
  End;
  NewWatch : PWatchItem;
  InsertDialog : PInsertWatchDialog;
  RegName : String[2];

Begin
  InsertDialog := New(PInsertWatchDialog,Init);
  InsertDialog^.PKindInputLine^.SetData(CurrentAddress);
  InsertDialog^.PKindRadio^.Value := Pred(wtAddress);
  If Owner^.Owner^.ExecView(InsertDialog) = cmOk then
    Begin
      InsertDialog^.PKindInputLine^.GetData(WatchInfo.Address);
      WatchInfo.Kind := Succ(InsertDialog^.PKindRadio^.Value);
      NewWatch := New(PWatchItem,Init);
      NewWatch^.Kind := WatchInfo.Kind;
      If WatchInfo.Kind =  wtAddress then
        NewWatch^.Address := WatchInfo.Address else
        Begin
          NewWatch^.RegName := RegNames[WatchInfo.Kind];
          Case WatchInfo.Kind of
            wtBC : NewWatch^.Register := @Engine^.ZRegs.BC;
            wtDE : NewWatch^.Register := @Engine^.ZRegs.DE;
            wtHL : NewWatch^.Register := @Engine^.ZRegs.HL;
            wtIX : NewWatch^.Register := @Engine^.IRegs.IX;
            wtIY : NewWatch^.Register := @Engine^.IRegs.IY;
            wtSP : NewWatch^.Register := @Engine^.IRegs.SP;
            wtPC : NewWatch^.Register := @Engine^.IRegs.PC;
          End;
        End;
      Watches^.AtInsert(Delta.Y+Cursor.Y,NewWatch);
      If Watches^.Count>=Size.Y then
        Begin
          Inc(Limit.Y);
          SetLimit(Limit.X,Limit.Y);
        End;
      VScrollBar^.SetRange(0,Watches^.Count);
    End;
  Dispose(InsertDialog,Done);
  DrawView;
End; {of TWatchViewer.AddWatch}

Procedure TWatchViewer.HandleEvent(var Event : TEvent);

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
    End;
  If Event.What = evCommand then
    Case Event.Command of
      cmAddWatch :
        Begin
          AddWatch;
          ClearEvent(Event);
        End;
      cmDeleteWatch :
        Begin
          RemoveWatch;
          ClearEvent(Event);
        End;
    End;
  If Event.What = evMouseDown then
    If ChangedCursor(Event.Where) then
      ClearEvent(Event);
End; {of TWatchViewer.HandleEvent}

Function TWatchViewer.ChangedCursor(GlobalPos : TPoint) : Boolean;

Var
  Pos : TPoint;

Begin
  MakeLocal(GlobalPos,Pos);
  If MouseInView(GlobalPos) and ((Pos.Y+Delta.Y) <= (Watches^.Count)) then
    Begin
       Cursor.Y := Pos.Y;
      VScrollBar^.SetValue(Cursor.Y+Delta.Y);
      DrawView;
    End;
End; {of TWatchViewer.ChangedCursor}

Procedure TWatchWindow.HandleEvent(var Event : TEvent);

Begin
  Inherited HandleEvent(Event);
  If (Event.What = evCommand) and (Event.Command = cmRedrawMemory) then
    Begin
      ReDraw;
      ClearEvent(Event);
    End;
End; {of TWatchWindow.HandleEvent}

Procedure TWatchViewer.ScrollDraw;

Begin
  If VScrollBar^.Value = Succ(Cursor.Y+Delta.Y) then
    If Cursor.Y=Pred(Size.Y) then
       Inc(Delta.Y) else
      Inc(Cursor.Y);
  If VScrollBar^.Value = Pred(Cursor.Y+Delta.Y) then
     If Cursor.Y=0 then
      Dec(Delta.Y) else
      Dec(Cursor.Y) else
     If VScrollBar^.Value <> (Cursor.Y+Delta.Y) then
       Begin
         If VScrollBar^.Value-Delta.Y < 0 then
           Begin
            Cursor.Y := 0;
            Delta.Y := VScrollBar^.Value;
          End else
        If VScrollBar^.Value-Delta.Y > Pred(Size.Y) then
           Begin
             Cursor.Y := Pred(Size.Y);
            Delta.Y := VScrollBar^.Value-Pred(Size.Y);
          End else
          Cursor.Y := VScrollBar^.Value;
      End;
  DrawView;
End; {of TWatchViewer.ScrollDraw}

Procedure TWatchViewer.ChangeBounds(var Bounds : TRect);

Begin
  SetBounds(Bounds);
  If Cursor.Y>Pred(Size.Y) then
    Cursor.Y := Pred(Size.Y);
  VScrollBar^.SetValue(Cursor.Y+Delta.Y);
  VScrollBar^.DrawView;
  DrawView;
End; {of TWatchViewer.ChangeBounds}

End. {of Unit ZWatch}
