Unit ZBreak;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#         Breakpoints          #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Uses
  Objects, Views, Drivers, Dialogs, ZEngine, ZGlobals, ZHex, ZConsts,
	ZInputs, MsgBox;

Type
  PBreakpointItem = ^TBreakpointItem;
  TBreakpointItem = Object(TObject)
  	PZMem : Pointer;
    Address : Word;
    OldCode, PassCount: Byte;
    Constructor Init(AnAddress : Word; APassCount : Byte; APZMem : Pointer);
    Destructor Done; virtual;
  End;

  PBreakpointCollection = ^TBreakpointCollection;
  TBreakpointCollection = Object(TCollection)
    PZMem : Pointer;
    MyAddress : Word;
    Constructor Init(APZMem : Pointer);
    Procedure Create(AnAddress : Word; APassCount : Byte);
    Function BreakAt(AnAddress : Word; var AResult : Byte) : Boolean;
    Function GetOld(AnAddress : Word) : Byte;
    Procedure Kill(AnAddress : Word);
    Procedure Error(Code, Info : Integer); virtual;
		Function Exists : Pointer;
  End;

  PBreakpointListBox = ^TBreakpointListBox;
  TBreakpointListBox = Object(TListBox)
    Function GetText(Item : Integer; MaxLen : Integer) : String; virtual;
  End;

  PBreakpointDialog = ^TBreakpointDialog;
  TBreakpointDialog = Object(TDialog)
  	VScrollBar : PScrollBar;
	  BreakpointListBox : PBreakpointListBox;
    BreakpointCollection : PBreakpointCollection;
    Constructor Init(ABreakpointCollection : PBreakpointCollection);
    Procedure HandleEvent(var Event : TEvent); virtual;
  End;

  PAddBreakpointDialog = ^TAddBreakpointDialog;
  TAddBreakpointDialog = Object(TDialog)
    BreakpointInputLine : PAddressInputLine;
    PasscountInputLine : PByteInputLine;
    BreakpointCollection : PBreakpointCollection;
    Constructor Init(ABreakpointCollection : PBreakpointCollection;
      AnAddress : Longint);
    Procedure HandleEvent(var Event : TEvent); virtual;
  End;

Implementation

{*********************************************************************}
{*********************************************************************}

Function TBreakpointListBox.GetText(Item : Integer; MaxLen : Integer) :
  String;

Var
  TempStr : String;
  Info : Record
    Address,
    Passcount,
    OldCode : Longint;
  End;

Begin
  With Info do
    Begin
      Address := Longint(PBreakpointItem(List^.At(Item))^.Address);
      Passcount := Longint(PBreakpointItem(List^.At(Item))^.Passcount);
      OldCode := Longint(PBreakpointItem(List^.At(Item))^.OldCode);
    End;
  If Pref.Base=0 then
    FormatStr(TempStr,' $%04x  $%02x  $%02x  ',Info) else
    FormatStr(TempStr,' %5d  %3d  %3d  ',Info);
  GetText := TempStr;
End;

{*********************************************************************}
{*********************************************************************}

Constructor TBreakpointDialog.Init(ABreakpointCollection :
	PBreakpointCollection);

Var
  R : TRect;
  PBreakpointButton : PButton;
  Info : Record
  	List : Pointer;
    Item : Word;
  End;

Begin
  R.Assign(0,0,26,16);
  Inherited Init(R,'Breakpoints');
  Options := Options or ofCentered;
	BreakpointCollection := ABreakpointCollection;

  R.Assign(22,3,23,10);
  VScrollBar := New(PScrollBar,Init(R));
  Insert(VScrollBar);

  R.Assign(3,3,22,10);
  BreakpointListBox := New(PBreakpointListBox,Init(R,1,VScrollBar));
  BreakpointListBox^.HelpCtx := hcBreakpointListBox;
  Info.List := BreakpointCollection;
  Info.Item := 0;
  BreakpointListBox^.SetData(Info);
  Insert(BreakpointListBox);

  R.Assign(3,2,20,3);
  Insert(New(PLabel,Init(R,'~A~ddress Pass Old',BreakpointListBox)));

  R.Assign(2,11,12,13);
  PBreakpointButton := New(PButton,Init(R,'O~k~',cmOk,bfDefault));
  PBreakpointButton^.HelpCtx := hcOkButton;
  Insert(PBreakpointButton);

  R.Assign(14,11,24,13);
  PBreakpointButton := New(PButton,Init(R,'~A~dd',cmAddBreakpoint,
  	bfDefault));
  PBreakpointButton^.HelpCtx := hcAddBreakpointButton;
  Insert(PBreakpointButton);

  R.Assign(14,13,24,15);
  PBreakpointButton := New(PButton,Init(R,'~R~emove',cmRemoveBreakpoint,
  	bfDefault));
  PBreakpointButton^.HelpCtx := hcRemoveBreakpointButton;
  Insert(PBreakpointButton);

  SelectNext(False);
End;

Procedure TBreakpointDialog.HandleEvent(var Event : TEvent);

Var
  Info : Record
  	List : PBreakpointCollection;
    Item : Word;
  End;

Begin
	If Event.What = evCommand then
  	Case Event.Command of
    	cmAddBreakpoint:
      	Begin
        	Owner^.ExecView(New(PAddBreakpointDialog,Init(BreakpointCollection,
        		0)));
          BreakpointListBox^.SetRange(BreakpointCollection^.Count);
          BreakpointListBox^.DrawView;
        	ClearEvent(Event);
        End;
      cmRemoveBreakpoint:
    		Begin
        	BreakpointListBox^.GetData(Info);
          If BreakpointCollection^.Count > 0 then
          	Begin
							Info.List^.Free(Info.List^.Items^[Info.Item]);
	            BreakpointListBox^.SetRange(Pred(BreakpointListBox^.Range));
							BreakpointListBox^.DrawView;
            End;
        	ClearEvent(Event);
        End;
    End;
	Inherited HandleEvent(Event);
End;

{*********************************************************************}
{*********************************************************************}

Constructor TAddBreakpointDialog.Init(ABreakpointCollection :
  PBreakpointCollection; AnAddress : Longint);

Var
  R : TRect;
  ANum : Longint;
  PBreakpointButton : PButton;

Begin
  R.Assign(0,0,27,11);
  Inherited Init(R,'Add Breakpoint');
  Options := Options or ofCentered;
  BreakpointCollection := ABreakpointCollection;

  R.Assign(3,3,13,4);
  BreakpointInputLine := New(PAddressInputLine,Init(R,
  	hcBreakpointInputLine));
  BreakpointInputLine^.SetData(AnAddress);
  Insert(BreakpointInputLine);
  R.Assign(2,2,21,3);
  Insert(New(PLabel,Init(R,'~B~reakpoint address',BreakpointInputLine)));

  R.Assign(3,6,13,7);
  PasscountInputLine := New(PByteInputLine,Init(R,hcPasscountInputLine));
  ANum := 0;
  PasscountInputLine^.SetData(ANum);
  Insert(PasscountInputLine);
  R.Assign(2,5,21,6);
  Insert(New(PLabel,Init(R,'~P~asscount',PasscountInputLine)));

  R.Assign(2,8,12,10);
  PBreakpointButton := New(PButton,Init(R,'O~k~',cmEnterBreakpoint,
  	bfDefault));
  PBreakpointButton^.HelpCtx := hcAddBreakpointButton;
  Insert(PBreakpointButton);

  R.Assign(14,8,24,10);
  PBreakpointButton := New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal));
  PBreakpointButton^.HelpCtx := hcCancelButton;
  Insert(PBreakpointButton);

  SelectNext(False);
End; {of TPasteDialog.Init}

Procedure TAddBreakpointDialog.HandleEvent(var Event : TEvent);

Var
  Address, Passcount : Longint;

Begin
  If (Event.What = evCommand) and (Event.Command = cmEnterBreakpoint) and
    BreakpointInputLine^.Valid(cmOk) and PasscountInputLine^.Valid(cmOk) then
      Begin
        BreakpointInputLine^.GetData(Address);
        PasscountInputLine^.GetData(Passcount);
        BreakpointCollection^.Create(Address,Passcount);
        Event.Command := cmOk;
      End;
	Inherited HandleEvent(Event);
End;

{*********************************************************************}
{*********************************************************************}

Constructor TBreakpointItem.Init(AnAddress : Word; APassCount : Byte; 
	APZMem : Pointer);

Begin
  Inherited Init;
  PZMem := APZMem;
  Address := AnAddress;
  PassCount := APassCount;
  OldCode := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Address))^);
  Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Address))^) := $76;
End;

Destructor TBreakpointItem.Done;

Begin
  Inherited Done;
  If Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Address))^) <> $76 then
  	Begin
	    If MessageBox(#3'The halt instruction at this'#13+
	      #3'breakpoint has been changed.'#13+
	      #3'Do you want to leave it like this?',nil,mfConfirmation or
	      mfYesButton or mfNoButton) = cmNo then
    End else
    Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Address))^) := OldCode;
End;

{*********************************************************************}
{*********************************************************************}

Function TBreakpointCollection.Exists : Pointer;

Var
	i : Integer;
  Temp : Pointer;

Begin
	Temp := nil;
	i := 0;
  If Count>0 then
  	Repeat
		  If PBreakpointItem(Items^[i])^.Address = MyAddress then
	    	Temp := Items^[i];
	    Inc(i);
	  Until (i >= Count) or (Temp <> nil);
  Exists := Temp;
End;

Constructor TBreakpointCollection.Init(APZMem : Pointer);

Begin
  Inherited Init(40,20);
  PZMem := APZMem;
End;

Procedure TBreakpointCollection.Create(AnAddress : Word; APassCount : Byte);

Begin
  MyAddress := AnAddress;
  If Exists <> nil then
    Error(coBreakpointExists,Integer(AnAddress)) else
    Insert(New(PBreakpointItem,Init(AnAddress,APassCount,PZMem)));
End;

Function TBreakpointCollection.BreakAt(AnAddress : Word; var AResult : Byte)
 	: Boolean;

Var
  BreakItem : PBreakpointItem;

Begin
	MyAddress := AnAddress;
  BreakItem := PBreakpointItem(Exists);
  If BreakItem = nil then
  	Begin
	  	BreakAt := False;
      AResult := exUserHalt;
    End else
    Begin
      If BreakItem^.PassCount = 1 then
      	BreakAt := True else
        BreakAt := False;
    	If BreakItem^.PassCount > 1 then
      	Begin
	      	Dec(BreakItem^.PassCount);
          AResult := exOk;
        End;
			If BreakItem^.PassCount = 0 then
      	Begin
        	Kill(AnAddress);
          AResult := exStop;
        End;
    End;
End;

Procedure TBreakpointCollection.Kill(AnAddress : Word);

Var
  BreakItem : PBreakpointItem;

Begin
  MyAddress := AnAddress;
  BreakItem := PBreakpointItem(Exists);
  If BreakItem <> nil then
    Free(BreakItem);
End;

Function TBreakpointCollection.GetOld(AnAddress : Word) : Byte;

Var
  BreakItem : PBreakpointItem;

Begin
  MyAddress := AnAddress;
  BreakItem := PBreakpointItem(Exists);
  If BreakItem <> nil then
    GetOld := BreakItem^.OldCode;
End;

Procedure TBreakpointCollection.Error(Code, Info : Integer);

Begin
  If Code = coBreakpointExists then
    MessageBox(#3'A breakpoint already exists'#13#13+
      #3'at this address',nil,mfError or mfOkButton) else
    Inherited Error(Code, Info);
End;

End.