Unit ZDialogs;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#           Dialogs            #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Uses
  Objects, Views, Dialogs, Drivers, Validate, ZStdDlg, ZConsts, MsgBox,
  ZValid, ZGlobals, ZInputs;

Type
  PPrintDialog = ^TPrintDialog;
  TPrintDialog = Object(TDialog)
    Constructor Init;
  End;

  PGotoDialog = ^TGotoDialog;
  TGotoDialog = Object(TDialog)
    Constructor Init;
  End;

  PFillDialog = ^TFillDialog;
  TFillDialog = Object(TDialog)
    Constructor Init;
  End;

  PLoadDialog = ^TLoadDialog;
  TLoadDialog = Object(TFileDialog)
    PLoadInputLine : PInputLine;
    Constructor Init(AWildCard : String);
  End;

  PSaveDialog = ^TSaveDialog;
  TSaveDialog = Object(TFileDialog)
    PSaveFromInputLine : PAddressInputLine;
    PSaveToInputLine : PAddressInputLine;
    Constructor Init(AWildCard : String);
  End;

  PPreferencesDialog = ^TPreferencesDialog;
  TPreferencesDialog = Object(TDialog)
    Constructor Init;
  End;

  PCopyDialog = ^TCopyDialog;
  TCopyDialog = Object(TDialog)
    PCopyFromInputLine : PAddressInputLine;
    PCopyToInputLine : PAddressInputLine;
    Constructor Init;
  End;

  PPasteDialog = ^TPasteDialog;
  TPasteDialog = Object(TDialog)
    Constructor Init;
  End;

  PFindDialog = ^TFindDialog;
  TFindDialog = Object(TDialog)
    PFindStringInputLine : PStringInputLine;
    Constructor Init;
  End;

  PReplaceDialog = ^TReplaceDialog;
  TReplaceDialog = Object(TDialog)
    PFindStringInputLine,
    PReplaceStringInputLine : PStringInputLine;
    Constructor Init;
    Function Valid(Command : Word) : Boolean; virtual;
  End;

  PInterruptModeDialog = ^TInterruptModeDialog;
  TInterruptModeDialog = Object(TDialog)
    Constructor Init;
  End;

  PInterruptDialog = ^TInterruptDialog;
  TInterruptDialog = Object(TDialog)
    PInterruptInput : PByteInputLine;
    Constructor Init;
  End;

Implementation

Constructor TPrintDialog.Init;

Var
  R : TRect;
  PPrintFromInputLine,
  PPrintToInputLine : PAddressInputLine;
  PPrintRadio : PRadioButtons;
  PPrintButton : PButton;

Begin
  R.Assign(0,0,26,14);
  Inherited Init(R,'Print');
  Options := Options or ofCentered;

  R.Assign(3,3,13,4);
  PPrintFromInputLine := New(PAddressInputLine,Init(R,
    hcPrintFromInputLine));
  Insert(PPrintFromInputLine);
  R.Assign(2,2,14,3);
  Insert(New(PLabel,Init(R,'Print ~f~rom',PPrintFromInputLine)));

  R.Assign(3,6,13,7);
  PPrintToInputLine := New(PAddressInputLine,Init(R,hcPrintToInputLine));
  Insert(PPrintToInputLine);
  R.Assign(2,5,11,6);
  Insert(New(PLabel,Init(R,'Print ~t~o',PPrintToInputLine)));

  R.Assign(3,9,13,12);
  PPrintRadio := New(PRadioButtons, Init(R,
    NewSItem('He~x~',
    NewSItem('~A~SCII',
    NewSItem('~C~ode',
    nil)))
  ));
  PPrintRadio^.HelpCtx := hcPrintRadio;
  Insert(PPrintRadio);
  R.Assign(2,8,13,9);
  Insert(New(PLabel,Init(R,'~P~rint in',PPrintRadio)));


  R.Assign(14,3,24,5);
  PPrintButton := New(PButton,Init(R,'O~k~',cmOk,bfDefault));
  PPrintButton^.HelpCtx := hcOkButton;
  Insert(PPrintButton);

  R.Assign(14,6,24,8);
  PPrintButton := New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal));
  PPrintButton^.HelpCtx := hcCancelButton;
  Insert(PPrintButton);

  SelectNext(False);
End;

Function TReplaceDialog.Valid(Command : Word) : Boolean;

Var
  TempValid,
  TempValid2 : Boolean;
  AnError : Boolean;

Begin
  If Inherited Valid(Command) and (Command <> cmCancel) then
  If UnformatStr(PFindStringInputLine^.Data^,AnError) =
    UnformatStr(PReplaceStringInputLine^.Data^,AnError) then
     Valid := True else
      Begin
        Valid := False;
        MessageBox(#3'Strings are not the'#13#13#3'same length',
          nil,mfError or mfOkButton);
      End else
    If Command = cmCancel then
      Valid := True else
      Valid := False;
End; {of TReplaceDialog.Valid}

Constructor TReplaceDialog.Init;

Var
  R : TRect;
  PReplaceButton : PButton;

Begin
  R.Assign(0,0,40,11);
  Inherited Init(R,'Replace');
  Options := Options or ofCentered;

  R.Assign(3,3,34,4);
  PFindStringInputLine := New(PStringInputLine,Init(R,255,
    hcFindInputLine));
  Insert(PFindStringInputLine);
  R.Assign(34,3,37,4);
  Insert(New(PHistory,Init(R,PFindStringInputLine,
    hsReplaceFindInputLine)));
  R.Assign(2,2,17,3);
  Insert(New(PLabel,Init(R,'~S~tring to find',PFindStringInputLine)));

  R.Assign(3,6,34,7);
  PReplaceStringInputLine := New(PStringInputLine,Init(R,255,
    hcReplaceInputLine));
  Insert(PReplaceStringInputLine);
  R.Assign(34,6,37,7);
  Insert(New(PHistory,Init(R,PReplaceStringInputLine,
    hsReplaceInputLine)));
  R.Assign(2,5,17,6);
  Insert(New(PLabel,Init(R,'~N~ew String',PReplaceStringInputLine)));

  R.Assign(15,8,25,10);
  PReplaceButton := New(PButton,Init(R,'O~k~',cmOk,bfDefault));
  PReplaceButton^.HelpCtx := hcOkButton;
  Insert(PReplaceButton);

  R.Assign(27,8,37,10);
  PReplaceButton := New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal));
  PReplaceButton^.HelpCtx := hcCancelButton;
  Insert(PReplaceButton);

  SelectNext(False);
End; {of TReplaceDialog.Init}

Constructor TFindDialog.Init;

Var
  R : TRect;
  PFindButton : PButton;

Begin
  R.Assign(0,0,39,8);
  Inherited Init(R,'Find');
  Options := Options or ofCentered;

  R.Assign(3,3,33,4);
  PFindStringInputLine := New(PStringInputLine,Init(R,255,
    hcFindInputLine));
  Insert(PFindStringInputLine);
  R.Assign(33,3,36,4);
  Insert(New(PHistory,Init(R,PFindStringInputLine,hsFindInputLine)));
  R.Assign(2,2,17,3);
  Insert(New(PLabel,Init(R,'~S~tring to find',PFindStringInputLine)));

  R.Assign(14,5,24,7);
  PFindButton := New(PButton,Init(R,'O~k~',cmOk,bfDefault));
  PFindButton^.HelpCtx := hcOkButton;
  Insert(PFindButton);

  R.Assign(26,5,36,7);
  PFindButton := New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal));
  PFindButton^.HelpCtx := hcCancelButton;
  Insert(PFindButton);

  SelectNext(False);
End; {of TFindDialog.Init}

Constructor TPasteDialog.Init;

Var
  R : TRect;
  PPasteInputLine : PAddressInputLine;
  PCopyButton : PButton;

Begin
  R.Assign(0,0,27,8);
  Inherited Init(R,'Paste');
  Options := Options or ofCentered;

  R.Assign(3,3,13,4);
  PPasteInputLine := New(PAddressInputLine,Init(R,hcPasteInputLine));
  Insert(PPasteInputLine);
  R.Assign(2,2,11,3);
  Insert(New(PLabel,Init(R,'~P~aste to',PPasteInputLine)));

  R.Assign(2,5,12,7);
  PCopyButton := New(PButton,Init(R,'O~k~',cmOk,bfDefault));
  PCopyButton^.HelpCtx := hcOkButton;
  Insert(PCopyButton);

  R.Assign(14,5,24,7);
  PCopyButton := New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal));
  PCopyButton^.HelpCtx := hcCancelButton;
  Insert(PCopyButton);

  SelectNext(False);
End; {of TPasteDialog.Init}

Constructor TCopyDialog.Init;

Var
  R : TRect;
  PCopyButton : PButton;

Begin
  R.Assign(0,0,27,11);
  Inherited Init(R,'Copy');
  Options := Options or ofCentered;

  R.Assign(3,3,13,4);
  PCopyFromInputLine := New(PAddressInputLine,Init(R,
    hcCopyFromInputLine));
  Insert(PCopyFromInputLine);
  R.Assign(2,2,12,3);
  Insert(New(PLabel,Init(R,'Copy ~f~rom',PCopyFromInputLine)));

  R.Assign(3,6,13,7);
  PCopyToInputLine := New(PAddressInputLine,Init(R,hcCopyToInputLine));
  Insert(PCopyToInputLine);
  R.Assign(2,5,10,6);
  Insert(New(PLabel,Init(R,'Copy ~t~o',PCopyToInputLine)));

  R.Assign(2,8,12,10);
  PCopyButton := New(PButton,Init(R,'O~k~',cmOk,bfDefault));
  PCopyButton^.HelpCtx := hcOkButton;
  Insert(PCopyButton);

  R.Assign(14,8,24,10);
  PCopyButton := New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal));
  PCopyButton^.HelpCtx := hcCancelButton;
  Insert(PCopyButton);

  SelectNext(False);
End; {of TCopyDialog.Init}

Constructor TInterruptDialog.Init;

Var
  R : TRect;
  PInterruptButton : PButton;

Begin
  R.Assign(0,0,20,8);
  Inherited Init(R,'Interrupt');
  Options := Options or ofCentered;

  R.Assign(3,3,9,4);
  PInterruptInput := New(PByteInputLine,Init(R,hcInterruptInput));
  Insert(PInterruptInput);
  R.Assign(2,2,19,3);
  Insert(New(PLabel,Init(R,'~I~nterrupt data',PInterruptInput)));

  R.Assign(7,5,17,7);
  PInterruptButton := New(PButton, Init(R,'O~k~',cmOk,bfDefault));
  PInterruptButton^.HelpCtx := hcOkButton;
  Insert(PInterruptButton);

  SelectNext(False);
End; {of TInterruptDialog.Init}

Constructor TInterruptModeDialog.Init;

Var
  R : TRect;
  PModeRadio : PRadioButtons;
  PInterruptButton : PButton;

Begin
  R.Assign(0,0,28,8);
  Inherited Init(R,'Interrupt Mode');
  Options := Options or ofCentered;

  R.Assign(3,3,25,4);
  PModeRadio := New(PRadioButtons, Init(R,
    NewSItem('~0~',
    NewSItem('~1~',
    NewSItem('~2~',
    nil)))
  ));
  PModeRadio^.HelpCtx := hcInterruptModeRadio;
  Insert(PModeRadio);
  R.Assign(2,2,13,3);
  Insert(New(PLabel,Init(R,'Interrupt Mode',PModeRadio)));

  R.Assign(3,5,13,7);
  PInterruptButton := New(PButton, Init(R,'O~k~',cmOk,bfDefault));
  PInterruptButton^.HelpCtx := hcOkButton;
  Insert(PInterruptButton);

  R.Assign(15,5,25,7);
  PInterruptButton := New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal));
  PInterruptButton^.HelpCtx := hcCancelButton;
  Insert(PInterruptButton);

  SelectNext(False);
End; {of TInterruptModeDialog.Init}

Constructor TPreferencesDialog.Init;

Var
  R : TRect;
  PPrefScreenRadio : PRadioButtons;
  PPrefBaseRadio : PRadioButtons;
  PPrefChecks : PCheckBoxes;
  PPrefButton : PButton;

Begin
  R.Assign(0,0,37,16);
  Inherited Init(R,'Preferences');
  Options := Options or ofCentered;

  R.Assign(3,3,34,4);
  PPrefScreenRadio := New(PRadioButtons, Init(R,
    NewSItem('~2~5 lines',
    NewSItem('~4~3/50 lines',
    nil))
  ));
  PPrefScreenRadio^.HelpCtx := hcScreenRadio;
  Insert(PPrefScreenRadio);
  R.Assign(2,2,15,3);
  Insert(New(PLabel,Init(R,'Screen sizes',PPrefScreenRadio)));

  R.Assign(3,6,34,7);
  PPrefBaseRadio := New(PRadioButtons, Init(R,
    NewSItem('~H~exadecimal',
    NewSItem('~D~ecimal',
    nil))
  ));
  PPrefBaseRadio^.HelpCtx := hcDefaultBaseRadio;
  Insert(PPrefBaseRadio);
  R.Assign(2,5,15,6);
  Insert(New(PLabel,Init(R,'Default base',PPrefBaseRadio)));

  R.Assign(3,8,34,12);
  PPrefChecks := New(PCheckBoxes, Init(R,
    NewSItem('D~i~splay #00-#1F',
    NewSItem('~P~rint #00-#1F',
    NewSItem('~U~pper case opcodes',
    NewSItem('~F~ollow PC in code window',
    nil))))
  ));
  PPrefChecks^.HelpCtx := hcPrefChecks;
  Insert(PPrefChecks);

  R.Assign(12,13,22,15);
  PPrefButton := New(PButton, Init(R,'O~k~',cmOk,bfDefault));
  PPrefButton^.HelpCtx := hcOkButton;
  Insert(PPrefButton);

  R.Assign(24,13,34,15);
  PPrefButton := New(PButton, Init(R,'~C~ancel',cmCancel,bfNormal));
  PPrefButton^.HelpCtx := hcCancelButton;
  Insert(PPrefButton);

  SelectNext(False);
End; {of TPreferencesDialog.Init}

Constructor TSaveDialog.Init(AWildCard : String);

Var
  R : TRect;

Begin
  Inherited Init(AWildCard,'Save File As','~S~ave file as',fdOkButton,
    hsSave);

  R.Assign(36,9,45,10);
  PSaveFromInputLine := New(PAddressInputLine,Init(R,
    hcSaveFromInputLine));
  Insert(PSaveFromInputLine);
  R.Assign(35,8,45,9);
  Insert(New(PLabel,Init(R,'Save ~f~rom',PSaveFromInputLine)));

  R.Assign(36,12,45,13);
  PSaveToInputLine := New(PAddressInputLine,Init(R,hcSaveToInputLine));
  Insert(PSaveToInputLine);
  R.Assign(35,11,43,12);
  Insert(New(PLabel,Init(R,'Save ~t~o',PSaveToInputLine)));
End; {of TSaveDialog.Init}

Constructor TLoadDialog.Init(AWildCard : String);

Var
  R : TRect;

Begin
  Inherited Init(AWildCard,'Load a File','~N~ame',fdOkButton,hsLoad);

  R.Assign(36,9,45,10);
  PLoadInputLine := New(PAddressInputLine,Init(R,hcLoadInputLine));
  Insert(PLoadInputLine);
  R.Assign(35,8,43,9);
  Insert(New(PLabel,Init(R,'~L~oad at',PLoadInputLine)));
End; {of TLoadDialog.Init}

Constructor TGotoDialog.Init;

Var
  R : TRect;
  PGotoInputLine : PAddressInputLine;
  PGotoButton : PButton;

Begin
  R.Assign(0,0,27,7);
  Inherited Init(R,'Go to');
  Options := Options or ofCentered;

  R.Assign(11,2,19,3);
  PGotoInputLine := New(PAddressInputLine,Init(R,hcGotoInputLine));
  Insert(PGotoInputLine);
  R.Assign(2,2,10,3);
  Insert(New(PLabel,Init(R,'~G~o to',PGotoInputLine)));

  R.Assign(2,4,12,6);
  PGotoButton := New(PButton,Init(R,'O~k~',cmOk,bfDefault));
  PGotoButton^.HelpCtx := hcOkButton;
  Insert(PGotoButton);

  R.Assign(14,4,24,6);
  PGotoButton := New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal));
  PGotoButton^.HelpCtx := hcCancelButton;
  Insert(PGotoButton);

  SelectNext(False);
End; {of TGotoDialog.Init}

Constructor TFillDialog.Init;

var
  R : TRect;
  PFillInputLine : PInputLine;
  PFillButton : PButton;

Begin
  R.Assign(0,0,27,11);
  Inherited Init(R,'Fill');
  Options := Options or ofCentered;

  R.Assign(14,2,22,3);
  PFillInputLine := New(PAddressInputLine,Init(R,hcFillFromInputLine));
  Insert(PFillInputLine);
  R.Assign(2,2,12,3);
  Insert(New(PLabel,Init(R,'Fill ~f~rom',PFillInputLine)));

  R.Assign(14,4,22,5);
  PFillInputLine := New(PAddressInputLine,Init(R,hcFillToInputLine));
  Insert(PFillInputLine);
  R.Assign(2,4,12,5);
  Insert(New(PLabel,Init(R,'       ~t~o',PFillInputLine)));

  R.Assign(14,6,22,7);
  PFillInputLine := New(PInputLine,Init(R,6));
  PFillInputLine^.SetValidator(New(PZRangeValidator,Init(0,255,
    Pref.Base=0)));
  PFillInputLine^.HelpCtx := hcFillWithInputLine;
  Insert(PFillInputLine);
  R.Assign(2,6,12,7);
  Insert(New(PLabel,Init(R,'     ~w~ith',PFillInputLine)));

  R.Assign(2,8,12,10);
  PFillButton := New(PButton,Init(R,'O~k~',cmOk,bfDefault));
  PFillButton^.HelpCtx := hcOkButton;
  Insert(PFillButton);

  R.Assign(14,8,24,10);
  PFillButton := New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal));
  PFillButton^.HelpCtx := hcCancelButton;
  Insert(PFillButton);

  SelectNext(False);
End; {of TFillDialog.Init}

End. {of Unit ZDialogs}
