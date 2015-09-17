Program ZiLEM;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#          The program         #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Uses
  ZTest286, Printer, App, Objects, Views, Dialogs, Menus, Drivers, MsgBox,
  Memory, ZStdDlg, ZConsts, ZHex, ZDialogs, ZGlobals, ZTerminl, ZEngine,
   ZRegDlg, ZWatch, ZBreak, HelpFile;

Type
  PZilemApp = ^TZilemApp;
  TZilemApp = Object(TApplication)
    PZMem : Pointer;
    SafetyByte : Pointer;
    FirstLoaded : Boolean;
    HexWindow : PHexWindow;
    RegistersDialog : PRegistersDialog;
    CodeWindow : PCodeWindow;
    WatchWindow : PWatchWindow;
    BreakpointCollection : PBreakpointCollection;
    Engine : PEngine;
    Terminal : PZTerminal;
    Constructor Init;
    Destructor Done; virtual;
    Procedure InitStatusLine; virtual;
    Procedure InitMenuBar; virtual;
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure ShowAboutDialog;
    Procedure ShowChDirDialog;
    Procedure WriteShellMsg; virtual;
    Procedure ShowGotoDialog;
    Procedure ShowFillDialog;
    Procedure ShowLoadDialog;
    Procedure ShowSaveDialog;
    Procedure ShowPreferencesDialog;
    Procedure ShowCopyDialog;
    Procedure ShowPasteDialog;
    Procedure ShowFindDialog;
    Procedure SearchAgain;
    Procedure ShowReplaceDialog;
    Procedure RunProgram;
    Procedure ShowModeDialog;
    Procedure DoInterrupt;
    Procedure DoNMI;
    Procedure Step;
    Procedure UpdateViews(ACommand : Word);
    Procedure ShowPrintDialog;
    Procedure OutOfMemory; virtual;
    Procedure GetEvent(var Event : TEvent); virtual;
  End;

Procedure TZilemApp.GetEvent(var Event : TEvent);

Var
  TheHelpStream : PStream;
  TheHelpFile : PHelpFile;
  TheHelpWindow : PHelpWindow;

Const
  HelpInUse : Boolean = False;

Begin
  Inherited GetEvent(Event);
      If ((Event.What = evCommand) and ((Event.Command = cmHelp) and
        not HelpInUse)) then
        Begin
          HelpInUse := True;
          TheHelpStream := New(PDosStream,Init('ZILHELP.HLP',stOpenRead));
          TheHelpFile := New(PHelpFile, Init(TheHelpStream));
          If TheHelpStream^.Status <> stOk then
            Begin
              MessageBox(#3'ZILEM.HLP'#13#13#3'can''t be found',nil,mfError or mfOkButton);
              Dispose(TheHelpFile,Done);
            End else
            Begin
              TheHelpWindow := New(PHelpWindow,Init(TheHelpFile, 1034));
              If ValidView(TheHelpWindow) <> nil then
                 ExecView(TheHelpWindow);
              Dispose(TheHelpWindow,Done);
              ClearEvent(Event);
            End;
          HelpInUse := False;
        End;
End;

Procedure TZilemApp.OutOfMemory;

Begin
  MessageBox(#3'Not enough memory to'#13#13#3'complete operation.',
    nil, mfError + mfOKButton);
End;

Procedure TZilemApp.ShowPrintDialog;

Var
  PrintInfo : Record
    Start,
    Finish : LongInt;
    Format : Integer;
  End;
  Temp : Longint;
  Address : Word;
  i : Word;
  c : Char;
  s : String;

Begin
  rewrite(lst);
  With PrintInfo do
    Begin
      Start := 0;
      Finish := 0;
      Format := 0;
    End;
  If ExecuteDialog(New(PPrintDialog,Init),@PrintInfo) = cmOk then
    Begin
      If PrintInfo.Start > PrintInfo.Finish then
        Begin
          Temp := PrintInfo.Start;
          PrintInfo.Start := PrintInfo.Finish;
          PrintInfo.Finish := Temp;
        End;
      Case PrintInfo.Format of
        0 : For Address := Word(PrintInfo.Start) to Word(PrintInfo.Finish)
          div 16 do
              Begin
                i := Address*16;
                FormatStr(s,'%04x',i);
                s := s+' : ';
                For i := Address*16 to Address*16+15 do
                  Begin
                    c := Char((Ptr(Seg(PZMem^),Ofs(PZmem^)+i))^);
                    AddHexSpace(Byte(c),s);
                  End;
                s := s+' ';
                For i := Address*16 to Address*16+15 do
                  Begin
                    c := Char((Ptr(Seg(PZMem^),Ofs(PZmem^)+i))^);
                    if c<#32 then
                      c := '.';
                    s := s+c;
                  End;
                Writeln(lst,s);
              End;
        1 : For Address := PrintInfo.Start to PrintInfo.Finish do
               Begin
                 c := Char((Ptr(Seg(PZMem^),Ofs(PZmem^)+Address))^);
                If ((Pref.Prefs and 2) = 0) and (c<#32) then
                   c := '.';
                Write(lst,c);
              End;
        2 : Begin
              Address := PrintInfo.Start;
              Repeat
                FormatStr(s,'%04x',Address);
                Write(lst,s,' : ');
                i := OpCode(PZMem,Address,s);
                Address := Address+i;
                Writeln(lst,s);
              Until Address>PrintInfo.Finish;
            End;
      End;
      Close(lst);
    End;
End; {of TZiLEMApp.ShowPrintDialog}

Procedure TZilemApp.UpdateViews(ACommand : Word);

Begin
  Message(RegistersDialog,evCommand,cmRedrawCode,nil);
  Message(CodeWindow,evCommand,ACommand,nil);
  Message(HexWindow,evCommand,cmRedrawMemory,nil);
  Message(WatchWindow,evCommand,cmRedrawMemory,nil);
End; {of TZiLEMApp.UpdateViews}

Procedure TZilemApp.DoInterrupt;

Var
  IntInfo : Longint;
  Switch : Boolean;

Begin
  If Engine^.ORegs.IFF1 then
    Begin
      Case Engine^.ORegs.IMode of
        0 : Begin
              If Terminal^.Mode = tmZ80 then
                Begin
                  Terminal^.ZiLEMScreen;
                  Switch := True;
                End else
                Switch := False;
              IntInfo := 0;
              Dec(Engine^.IRegs.PC);
              ExecuteDialog(New(PInterruptDialog,Init),@IntInfo);
              If Switch then
                Terminal^.Z80Screen;
              Engine^.Execute(Byte(IntInfo));
            End;
        1 : Engine^.DoCall($38);
        2 : Begin
              If Terminal^.Mode = tmZ80 then
                Begin
                  Terminal^.ZiLEMScreen;
                  Switch := True;
                End else
                Switch := False;
              IntInfo := 0;
              ExecuteDialog(New(PInterruptDialog,Init),@IntInfo);
              If Switch then
                Terminal^.Z80Screen;
              Engine^.DoCall((Engine^.ORegs.I * $100) +
                (Byte(IntInfo) and ($FF-1)));
            End;
      End;
      Engine^.ORegs.IFF1 := False;
      Engine^.ORegs.IFF2 := False;
    End;
End; {of TZiLEMApp.DoInterrupt}

Procedure TZilemApp.DoNMI;

Begin
  Engine^.IRegs.PC := $66;
  Engine^.ORegs.IFF1 := False;
End; {of TZiLEMApp.DoNMI}

Procedure TZilemApp.ShowReplaceDialog;

Var
  ReplaceInfo : record
    Find : String[255];
    Replace : String[255];
  End;

Begin
  With ReplaceInfo do
    Begin
      Find := '';
      Replace := '';
    End;
  If ExecuteDialog(New(PReplaceDialog,Init),@ReplaceInfo) = cmOk then
    With SearchInfo do
      Begin
        Replace := True;
        FindString := ReplaceInfo.Find;
        ReplaceString := ReplaceInfo.Replace;
        SearchAgain;
      End;
End; {of TZiLEMApp.ShowReplaceDialog}

Procedure TZilemApp.ShowFindDialog;

Var
  FindInfo : record
    S : String[255];
  End;
  i : Word;
  Found : Boolean;

Begin
  With FindInfo do
    S := '';
  If ExecuteDialog(New(PFindDialog,Init),@FindInfo) = cmOk then
    Begin
      SearchInfo.Replace := False;
      SearchInfo.FindString := FindInfo.S;
      SearchAgain;
    End;
End; {of TZiLEMApp.ShowFindDialog}

Procedure TZilemApp.ShowModeDialog;

Var
  ModeInfo : Integer;

Begin
  ModeInfo := Engine^.ORegs.IMode;
  If ExecuteDialog(New(PInterruptModeDialog,Init),@ModeInfo) = cmOk then
    Engine^.ORegs.IMode := ModeInfo;
End; {of TZiLEMApp.ShowModeDialog}

Procedure TZilemApp.SearchAgain;

Var
  i , offset : Word;
  Found : Boolean;

Begin
  With SearchInfo do
    If not (FindString='') then
      Begin
        i := CurrentAddress;
        Offset := 1;
        Found := False;
        Repeat
          If Char((Ptr(Seg(PZMem^),Ofs(PZmem^)+i))^)=FindString[Offset]
            then
            Begin
              Inc(Offset);
              If Offset>Length(FindString) then
                Found := True;
            End else
            Begin
              i := Succ(i)-offset;
              Offset := 1;
              Found := False;
            End;
          Inc(i);
        Until Found or (i>MemorySize) or (i=0);
        If Found then
          Begin
            CurrentAddress := i;
            CurrentPos := 0;
            Message(HexWindow,evCommand,cmUpdateMemoryPos,@self);
          End else
          MessageBox(#3'Search string not found',nil,
            mfError or mfOkButton);
        If Replace then
          For i := CurrentAddress-Length(FindString) to CurrentAddress-1
            do
            Char((Ptr(Seg(PZMem^),Ofs(PZmem^)+i))^) :=
              ReplaceString[Length(FindString)-CurrentAddress+Succ(i)];
            Message(HexWindow,evCommand,cmRedrawMemory,@Self);
      End;
End; {of TZiLEMApp.SearchAgain}

Procedure TZilemApp.ShowPasteDialog;

Var
  PasteInfo : record
    Address : Longint;
  End;
  i : Word;
  Finish : Word;

Begin
  PasteInfo.Address := CurrentAddress;
  If ExecuteDialog(New(PPasteDialog,Init),@PasteInfo) = cmOk then
    Begin
      If PasteInfo.Address+Clip.Size>MemorySize then
        Finish := MemorySize else
        Finish := PasteInfo.Address+Clip.Size;
      For i := PasteInfo.Address to Finish do
        Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+i))^) :=
          Byte((Ptr(Seg(Clip.Data^),Ofs(Clip.Data^)+i-
            PasteInfo.Address))^);
      If Clip.Big and (PasteInfo.Address = 0) then
        Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+$FFFF))^) := Clip.LastByte;
      Message(HexWindow,evCommand,cmRedrawMemory,@Self);
      Message(RegistersDialog,evCommand,cmRedrawCode,nil);
      Message(CodeWindow,evCommand,cmRedrawCode,nil);
    End;
End; {of TZiLEMApp.ShowPasteDialog}

Procedure TZilemApp.ShowCopyDialog;

Var
  CopyInfo : record
    Start, Finish : Longint;
  End;
  i : Longint;

Begin
  With CopyInfo do
    Begin
      Start := CurrentAddress;
      Finish := CurrentAddress;
    End;
  If ExecuteDialog(New(PCopyDialog,Init),@CopyInfo) = cmOk then
  With CopyInfo do
    Begin
      FreeMem(Clip.Data,Clip.Size);
      If Start>Finish then
        Begin
          i := Start;
          Start := Finish;
          Finish := i;
        End;
      Clip.Size := Finish-Start+1;
      If Clip.Size = 0 then
        Begin
          Clip.LastByte := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+$FFFF))^);
          Clip.Big := True;
          Dec(Finish);
          Dec(Clip.Size);
        End else
        Clip.Big := False;
      If (MaxAvail < Clip.Size) then
        Begin
          MessageBox(#3'Not enough memory to'#13#13#3'copy this much',
            nil,mfError or mfOkButton);
          GetMem(Clip.Data,0);
        End else
        Begin
          GetMem(Clip.Data,Clip.Size);
          For i := Start to Finish do
            Byte((Ptr(Seg(Clip.Data^),Ofs(Clip.Data^)+i-Start))^) :=
              Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+i))^);
        End;
    End;
End; {of TZiLEMApp.ShowCopyDialog}

Procedure TZilemApp.ShowPreferencesDialog;

Var
  PrefInfo : TPrefs;

Begin
  PrefInfo := Pref;
  If ExecuteDialog(New(PPreferencesDialog,Init),@PrefInfo) = cmOk then
    Begin
      If PrefInfo.ScreenSize <> Pref.ScreenSize then
        SetScreenMode(ScreenMode xor smFont8x8);
      Pref := PrefInfo;
      Owner^.Redraw;
      UpdateViews(cmRedrawCode);
    End;
End; {of TZiLEMApp.ShowPreferencesDialog}

Procedure TZilemApp.ShowSaveDialog;

Var
  SaveInfo : record
    FileName : FNameStr;
    SaveFromAddress : Longint;
    SaveToAddress : Longint;
  end;
  SaveFrom, SaveTo : Word;
  Code : Integer;
  i : Word;
  PSaveStream : PBufStream;
  PSaveBuf : Pointer;
  SaveDialog : PSaveDialog;

Begin
  SaveInfo.SaveFromAddress := Longint(Address.Start);
  SaveInfo.SaveToAddress := Longint(Address.Finish);
  SaveDialog := New(PSaveDialog,Init('*.z80'));
  SaveDialog^.PSaveFromInputLine^.SetData(SaveInfo.SaveFromAddress);
  SaveDialog^.PSaveToInputLine^.SetData(SaveInfo.SaveToAddress);
  If ExecView(SaveDialog) = cmFileOpen
    then
    Begin
      SaveDialog^.PSaveFromInputLine^.GetData(SaveInfo.SaveFromAddress);
      SaveDialog^.PSaveToInputLine^.GetData(SaveInfo.SaveToAddress);
      SaveInfo.FileName := SaveDialog^.Directory^+SaveDialog^.FileName^.Data^;
      PSaveStream := New(PBufStream,Init(SaveInfo.FileName,stCreate,512));
      GetMem(PSaveBuf,1);
      If SaveInfo.SaveFromAddress > SaveInfo.SaveToAddress then
        Begin
          i := SaveInfo.SaveFromAddress;
          SaveInfo.SaveFromAddress := SaveInfo.SaveToAddress;
          SaveInfo.SaveToAddress := i;
        End;
      If PSaveStream^.ErrorInfo = stOk then
        For i := SaveInfo.SaveFromAddress to SaveInfo.SaveToAddress do
          Begin
            Byte(PSaveBuf^) := Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+i))^);
            PSaveStream^.Write(PSaveBuf^,1);
          End;
      FreeMem(PSaveBuf,1);
      PSaveStream^.Done;
      Message(HexWindow,evCommand,cmRedrawMemory,@Self);
    End;
  Dispose(SaveDialog,Done);
End; {of TZiLEMApp.ShowSaveDialog}

Procedure TZilemApp.ShowLoadDialog;

Var
  LoadInfo : record
    FileName : FNameStr;
    LoadAddress : Longint;
  end;
  LoadAt : Word;
  Code : Integer;
  i : Word;
  PLoadStream : PBufStream;
  PLoadBuf : Pointer;
  FileSize : LongInt;
  LoadDialog : PLoadDialog;

Begin
  LoadInfo.LoadAddress := Longint(CurrentAddress);
  LoadDialog := New(PLoadDialog,Init('*.z80'));
  LoadDialog^.PLoadInputLine^.SetData(LoadInfo.LoadAddress);
  If ExecView(LoadDialog) = cmFileOpen
    then
    Begin
      LoadDialog^.PLoadInputLine^.GetData(LoadAt);
      LoadInfo.FileName := LoadDialog^.Directory^+LoadDialog^.FileName^.Data^;
      PLoadStream := New(PBufStream,Init(LoadInfo.FileName,stOpenRead,
        512));
      FileSize := PLoadStream^.GetSize;
      GetMem(PLoadBuf,1);
      If (LongInt(LoadAt)+FileSize)>MemorySize then
        FileSize := MemorySize-LongInt(LoadAt)+1;
      Address.Start := LoadAt;
      Address.Finish := Word(LoadAt+Pred(FileSize));
      If PLoadStream^.ErrorInfo = stOk then
        For i := Address.Start to Address.Finish do
          Begin
            PLoadStream^.Read(PLoadBuf^,1);
            Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+i))^) := Byte(PLoadBuf^);
          End;
      FreeMem(PLoadBuf,1);
      PLoadStream^.Done;
      Message(HexWindow,evCommand,cmRedrawMemory,@Self);
      Message(RegistersDialog,evCommand,cmRedrawCode,nil);
      Message(CodeWindow,evCommand,cmRedrawCode,nil);
    End;
  Dispose(LoadDialog,Done);
End; {of TZiLEMApp.ShowLoadDialog}

Procedure TZilemApp.ShowFillDialog;

Var
  Code : Word;
  NStart,NFinish,NFiller : Word;
  FillInfo : record
    Start : Longint;
    Finish : Longint;
    Filler : Longint;
  End;

Begin
  With FillInfo do
    Begin
      Start := Longint(Address.Start);
      Finish := Longint(Address.Finish);
      Filler := 0;
    End;
  If ExecuteDialog(New(PFillDialog,Init),@FillInfo) = cmOk then
    Begin
      With FillInfo do
        Begin
          NStart := Word(Start);
          NFinish := Word(Finish);
          NFiller := Word(Filler);
        End;
      If NStart > NFinish then
        Begin
          Code := NStart;
          NStart := NFinish;
          NFinish := Code;
        End;
      For Code := NStart to NFinish do
        Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Code))^) := NFiller;
      Message(HexWindow,evCommand,cmRedrawMemory,@Self);
      Message(RegistersDialog,evCommand,cmRedrawCode,nil);
      Message(CodeWindow,evCommand,cmRedrawCode,nil);
    End;
End; {of TZiLEMApp.ShowFillDialog}

Procedure TZilemApp.ShowGotoDialog;

Var
  GotoInfo : Record
    Address : Longint;
  End;
  Code : Integer;

Begin
  GotoInfo.Address := Longint(CurrentAddress);
  ExecuteDialog(New(PGotoDialog,Init),@GotoInfo);
  If @Desktop^.Current^ = @HexWindow^ then
    Begin
      CurrentAddress := Word(GotoInfo.Address);
      CurrentPos := 0;
    End else
  If @Desktop^.Current^ = @CodeWindow^ then
    Begin
      CodeWindow^.Interior^.StartAt := Word(GotoInfo.Address);
      CodeWindow^.Interior^.CursorAt := Word(GotoInfo.Address);
      CodeWindow^.Interior^.Cursor.Y := 0;
      UpdateViews(cmRedrawCode);
    End;
  Message(HexWindow,evCommand,cmUpdateMemoryPos,@self);
End; {of TZiLEMApp.ShowGotoDialog}

Procedure TZilemApp.WriteShellMsg;

Begin
  PrintStr('Type EXIT to return to ZiLEM...');
End; {of TZiLEMApp.WriteShellMsg}

Constructor TZilemApp.Init;

Var
  R : TRect;

Begin
  Inherited Init;
  GetMem(PZMem,$FFFF);
  GetMem(SafetyByte,1);
  If PZMem = nil then
    Begin
      SetVideoMode(StartupMode);
      ClearScreen;
      InLine($B4/$01/$B9/$07/$06/$CD/$10);
      PrintStr('Not enought memory to run ZiLEM');
      Halt(1);
    End;
  FirstLoaded := True;
  If Pref.ScreenSize = 0 then
    SetScreenMode(ScreenMode and not smFont8x8) else
    SetScreenMode(ScreenMode and smFont8x8);
  GetExtent(R);
  R.Assign(0,0,75,R.B.Y-2);
  HexWindow := New(PHexWindow,Init(R,PZMem));
  Desktop^.Insert(HexWindow);
  Terminal := New(PZTerminal, Init(Desktop,MenuBar,StatusLine));
  Engine := New(PEngine, Init(PZMem, Terminal));
  RegistersDialog := New(PRegistersDialog, Init(PZMem,Engine));
  RegistersDialog^.Hide;
  Desktop^.Insert(RegistersDialog);
  R.Assign(19,0,42,23);
  CodeWindow := New(PCodeWindow, Init(R,PZMem,Engine));
  CodeWindow^.Hide;
  Desktop^.Insert(CodeWindow);
  R.Assign(0,17,80,23);
  WatchWindow := New(PWatchWindow, Init(R, PZMem, Engine));
  WatchWindow^.Hide;
  Desktop^.Insert(WatchWindow);
  RegisterHelpFile;
  BreakpointCollection := New(PBreakpointCollection,Init(PZMem));
  Redraw;
End; {of TZiLEMApp.Init}

Destructor TZilemApp.Done;

Begin
  Inherited Done;
  FreeMem(PZMem,$FFFF);
  FreeMem(SafetyByte,1);
End; {of TZiLEMApp.Done}

Procedure TZilemApp.ShowAboutDialog;

Var
  R : TRect;
  MemFree : Longint;

Begin
  MemFree := MaxAvail div 1024;
  R.Assign(18,Size.Y div 2 - 7,62,Size.Y div 2 + 6);
  MessageBoxRect(R,#3'ZiLEM Z80 Emulator'#13#13+
    #3'Version 0.8'#13#13#3'Copyright (c) 1994 by James Ots'#13#13#3+
    '%dKb Free',@MemFree,mfInformation or mfOkButton);
End; {of TZiLEMApp.ShowAboutDialog}

Procedure TZilemApp.ShowChDirDialog;

Begin
  ExecuteDialog(New(PChDirDialog,Init(cdNormal,hsChDir)),nil);
End; {of TZiLEMApp.ShowChDirDialog}

Procedure TZilemApp.InitStatusLine;

Var
  R : TRect;

Begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PZilemStatusLine,Init(R,
    NewStatusDef($0000,$03E7,
      NewStatusKey('~F1~ Help',kbF1,cmHelp,
      NewStatusKey('~F2~ Save as',kbF2,cmSaveAs,
      NewStatusKey('~F3~ Load',kbF3,cmLoad,
      NewStatusKey('~F7~ Trace',kbF7,cmTrace,
      NewStatusKey('~F8~ Step',kbF8,cmStep,
      NewStatusKey('~F9~ Run',kbF9,cmRun,

      StdStatusKeys(
      nil))))))),
    NewStatusDef($03E8,Pred(hcWatchWindow),
      NewStatusKey('~F1~ Help',kbF1,cmHelp,
      StdStatusKeys(
      nil)),
    NewStatusDef(hcWatchWindow,hcWatchWindow,
      NewStatusKey('~F1~ Help',kbF1,cmHelp,
      NewStatusKey('~F7~ Trace',kbF7,cmTrace,
      NewStatusKey('~F8~ Step',kbF8,cmStep,
      NewStatusKey('~Ins~ Add',kbIns,cmAddWatch,
      NewStatusKey('~Del~ Delete',kbDel,cmDeleteWatch,
      StdStatusKeys(
      nil)))))),
    NewStatusDef(hcCodeWindow,hcCodeWindow,
      NewStatusKey('~F1~ Help',kbF1,cmHelp,
      NewStatusKey('~F2~ Save as',kbF2,cmSaveAs,
      NewStatusKey('~F3~ Load',kbF3,cmLoad,
      NewStatusKey('~F7~ Trace',kbF7,cmTrace,
      NewStatusKey('~F8~ Step',kbF8,cmStep,
      NewStatusKey('~F9~ Run',kbF9,cmRun,
      NewStatusKey('~Enter~ Assemble',kbEnter,cmAssemble,
      StdStatusKeys(
      nil)))))))),
    NewStatusDef(Succ(hcHexWindow),$FFFF,
      NewStatusKey('~F1~ Help',kbF1,cmHelp,
      StdStatusKeys(
      nil)),
    nil))))
  )));
End; {of TZiLEMApp.InitStatusLine}

Procedure TZilemApp.InitMenuBar;

Var
  R : TRect;

Begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~F~ile',hcFile,NewMenu(
      NewItem('~L~oad...','F3',kbF3,cmLoad,hcLoad,
      NewItem('~S~ave as...','F2',kbF2,cmSaveAs,hcSaveAs,
      NewLine(
      NewItem('~C~hange dir...','',kbNoKey,cmChangeDir,hcChangeDir,
      NewItem('~P~rint...','',kbNoKey,cmPrint,hcPrint,
      NewItem('~D~OS Shell','',kbNoKey,cmDosShell,hcDosShell,
      NewLine(
      NewItem('E~x~it','Alt+X',kbAltX,cmQuit,hcQuit,
      nil))))))))
    ),
    NewSubMenu('~E~dit',hcEdit,NewMenu(
      NewItem('~F~ill...','',kbNoKey,cmFill,hcFill,
      NewLine(
      NewItem('~C~opy...','Ctrl+Ins',kbCtrlIns,cmCopy,hcCopy,
      NewItem('~P~aste...','Shift+Ins',kbShiftIns,cmPaste,hcPaste,
      nil))))
    ),
    NewSubMenu('~S~earch',hcSearch,NewMenu(
      NewItem('~F~ind...','',kbNoKey,cmFind,hcFind,
      NewItem('~R~eplace...','',kbNoKey,cmReplace,hcReplace,
      NewItem('~S~earch again','',kbNoKey,cmSearchAgain,hcSearchAgain,
      NewLine(
      NewItem('~G~o to address...','',kbNoKey,cmGoto,hcGoto,
      nil)))))
    ),
    NewSubMenu('~R~un',hcRunMenu,NewMenu(
      NewItem('~R~un','F9',kbF9,cmRun,hcRun,
      NewItem('~S~tep over','F8',kbF8,cmStep,hcStep,
      NewItem('~T~race into','F7',kbF7,cmTrace,hcTrace,
      NewItem('~G~o to cursor','F4',kbF4,cmGoToCursor,hcGoToCursor,
      nil))))
    ),
    NewSubMenu('In~t~errupts',hcInterrupts,NewMenu(
      NewItem('~M~ode...','',kbNoKey,cmMode,hcMode,
      NewLine(
      NewItem('~I~nterrupt','Alt+I',kbAltI,cmInterrupt,hcInterrupt,
      NewItem('~N~MI','Alt+N',kbAltN,cmNMI,hcNMI,
      nil))))
    ),
    NewSubMenu('~D~ebug',hcDebug,NewMenu(
      NewItem('~B~reakpoints...','',kbNoKey,cmBreakpoints,hcBreakpoints,
      NewItem('~W~atches','',kbNoKey,cmWatch,hcWatch,
      NewItem('~C~ode','',kbNoKey,cmCode,hcCode,
      NewItem('CPU ~R~egisters','',kbNoKey,cmShowRegisters,hcShowRegisters,
      NewItem('~M~emory','',kbNoKey,cmShowMemory,hcShowMemory,
      NewItem('~U~ser screen','Alt+F5',kbAltF5,cmUserScreen,hcUserScreen,
      NewLine(
      NewItem('~A~dd watch...','Ctrl+F7',kbCtrlF7,cmAddWatch,hcAddWatch,
      NewItem('Add break~p~oint...','',kbNoKey,cmAddBreakpoint,
        hcAddBreakpoint,
      nil)))))))))
    ),
    NewSubMenu('~O~ptions',hcOptions,NewMenu(
      NewItem('~T~erminal...','',kbNoKey,cmTerminal,hcTerminal,
      NewItem('~C~olours...','',kbNoKey,cmColours,hcColours,
      NewItem('~P~references...','',kbNoKey,cmPreferences,hcPreferences,
      NewLine(
      NewItem('~O~pen...','',kbNoKey,cmOptionsOpen,hcOptionsOpen,
      NewItem('~S~ave...','',kbNoKey,cmOptionsSave,hcOptionsSave,
      NewItem('Save ~a~s...','',kbNoKey,cmOptionsSaveAs,hcOptionsSaveAs,
      nil)))))))
    ),
    NewSubMenu('~W~indow',hcWindow,NewMenu(
      NewItem('~R~edraw Code','Shift+F5',kbShiftF5,cmRedrawAll,
        hcRedrawCode,
      NewItem('~S~ize/Move','Ctrl+F5',kbCtrlF5,cmResize,hcResize,
      NewItem('~Z~oom','F5',kbF5,cmZoom,hcZoom,
      NewItem('~N~ext','F6',kbF6,cmNext,hcNext,
      NewItem('~P~revious','Shift+F6',kbShiftF6,cmPrev,hcPrev,
      NewItem('~C~lose','Alt+F3',kbAltF3,cmClose,hcClose,
      nil))))))
    ),
    NewSubMenu('~H~elp',hcHelp,NewMenu(
      NewItem('~I~ndex','Shift+F1',kbShiftF1,cmIndex,hcIndex,
      NewItem('~T~opic search','Ctrl+F1',kbCtrlF1,cmTopic,hcTopic,
      NewItem('~P~revious topic','Alt+F1',kbAltF1,cmPreviousTopic,
        hcPreviousTopic,
      NewLine(
      NewItem('~U~sing the emulator','',kbNoKey,cmUsing,hcUsing,
      NewItem('~Z~80 mnemonics','',kbNoKey,cmZ80,hcZ80,
      NewLine(
      NewItem('~A~bout...','',kbNoKey,cmAbout,hcAbout,
      nil))))))))
    ),
  nil))))))))))));
End; {of TZiLEMApp.InitMenuBar}

Procedure TZilemApp.Step;

Begin
  If ((Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Engine^.IRegs.PC))^) and $C4) = $C4) {or
    ((Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Engine^.IRegs.PC))^)
      and $64) = $64)} then
    Begin
      BreakpointCollection^.Create(Engine^.IRegs.PC+3,0);
      RunProgram;
    End else
    Begin
      Engine^.Execute(Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Engine^.IRegs.PC))^));
      UpdateViews(cmChangedPC);
    End;
End; {of TZiLEMApp.Step}

Procedure TZilemApp.RunProgram;

Label
  RunHere;

Var
  Result : Byte;

Begin
  CtrlBreakHit := False;
  Terminal^.Z80Screen;
  Repeat
    Repeat
      Result := Engine^.Execute(Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Engine^.IRegs.PC))^));
    Until Result <> exOk;
    Case Result of
      exInt : DoInterrupt;
      exNMI : DoNMI;
      exHalt : If BreakpointCollection^.BreakAt(Engine^.IRegs.PC-1,Result) then
        Begin
          Dec(Engine^.IRegs.PC);
          Engine^.Execute(BreakpointCollection^.GetOld(Engine^.IRegs.PC-1));
        End else
        Dec(Engine^.IRegs.PC);
    End;
  Until (Result in [exHalt,exBreak,exStop,exUserHalt]);
  Terminal^.ZiLEMScreen;
  UpdateViews(cmChangedPC);
  Case Result of
    exStop : MessageBox(#3'Breakpoint encountered'#13#13+
      #3'and cleared',nil,mfInformation or mfOkButton);
    exBreak : MessageBox(#3'Ctrl-Break Pressed',nil,mfInformation or
      mfOkButton);
    exUserHalt :
      Begin
        Inc(Engine^.IRegs.PC);
        MessageBox(#3'Breakpoint encountered',nil,mfInformation or
          mfOkButton);
      End;
  End;
End; {of TZiLEMApp.RunProgram}

Procedure TZilemApp.HandleEvent(var Event : TEvent);

Var
  Dummy : Byte;

Begin
  Inherited HandleEvent(Event);
  If FirstLoaded then
    Begin
      Event.What := evCommand;
      Event.Command := cmAbout;
      FirstLoaded := False;
    End;
  If Event.What = evCommand then
    Case Event.Command of
      cmAbout :
        begin
          ShowAboutDialog;
          ClearEvent(Event);
        end;
      cmChangeDir :
        begin
          ShowChDirDialog;
          ClearEvent(Event);
        end;
      cmGoto :
        begin
          ShowGotoDialog;
          ClearEvent(Event);
        end;
      cmFill :
        begin
          ShowFillDialog;
           ClearEvent(Event);
        end;
      cmLoad :
        begin
          ShowLoadDialog;
          ClearEvent(Event);
        end;
      cmSaveAs :
        begin
          ShowSaveDialog;
          ClearEvent(Event);
        end;
      cmPreferences :
        begin
          ShowPreferencesDialog;
          ClearEvent(Event);
        end;
      cmCopy :
        begin
          ShowCopyDialog;
          ClearEvent(Event);
        end;
      cmPaste :
        begin
          ShowPasteDialog;
          ClearEvent(Event);
        end;
      cmFind :
        begin
          ShowFindDialog;
          ClearEvent(Event);
        end;
      cmSearchAgain :
        begin
          SearchAgain;
          ClearEvent(Event);
        end;
      cmReplace :
        begin
          ShowReplaceDialog;
          ClearEvent(Event);
        end;
      cmMode :
        begin
          ShowModeDialog;
          ClearEvent(Event);
        end;
      cmUserScreen :
        begin
          Terminal^.Z80Screen;
          If Terminal^.ReadChar = #0 then
            Terminal^.ReadChar;
          Terminal^.ZiLEMScreen;
          ClearEvent(Event);
        end;
      cmIndex,cmTopic,cmPreviousTopic,cmUsing,cmZ80,cmColours,
        cmTerminal :
        begin
          MessageBox(#3'Not available in'#13#13#3'this version',
            nil,mfWarning or mfOkButton);
          ClearEvent(Event);
        end;
      cmRun :
        begin
          RunProgram;
          ClearEvent(Event);
        end;
      cmStep :
        begin
          Step;
          ClearEvent(Event);
        end;
      cmTrace :
        begin
          If Engine^.Execute(Byte((Ptr(Seg(PZMem^),Ofs(PZmem^)+Engine^.IRegs.PC))^)) = exHalt then
            If BreakpointCollection^.BreakAt(Engine^.IRegs.PC-1,Dummy) or
              (Dummy = exUserHalt) then
              Begin
                MessageBox(#3'Breakpoint encountered',nil,mfInformation or
                  mfOkButton);
              End;
          UpdateViews(cmChangedPC);
          ClearEvent(Event);
        end;
      cmRedrawCode :
        begin
          UpdateViews(cmRedrawCode);
          ClearEvent(Event);
        end;
      cmRedrawAll :
        begin
          UpdateViews(cmRedrawCode);
          ClearEvent(Event);
        end;
      cmRedrawMemory :
        begin
          Message(WatchWindow,evCommand,cmRedrawMemory,nil);
          ClearEvent(Event);
        end;
      cmWatch :
        begin
          WatchWindow^.Show;
          WatchWindow^.Select;
          ClearEvent(Event);
        end;
      cmAddWatch :
        begin
          WatchWindow^.Show;
          WatchWindow^.Select;
          Message(WatchWindow,evCommand,cmAddWatch,nil);
          ClearEvent(Event);
        end;
      cmPrint :
        begin
          ShowPrintDialog;
          ClearEvent(Event);
        end;
      cmInterrupt :
        begin
          DoInterrupt;
          UpdateViews(cmChangedPC);
          ClearEvent(Event);
        end;
      cmNMI :
        begin
          DoNMI;
          UpdateViews(cmChangedPC);
          ClearEvent(Event);
        end;
      cmCode :
        begin
          CodeWindow^.Show;
          CodeWindow^.Select;
          ClearEvent(Event);
        end;
      cmShowRegisters :
        begin
          RegistersDialog^.Show;
          RegistersDialog^.Select;
          ClearEvent(Event);
        end;
      cmShowMemory :
        begin
          HexWindow^.Show;
          HexWindow^.Select;
          ClearEvent(Event);
        end;
      cmAddBreakpoint :
        begin
          ExecuteDialog(New(PAddBreakpointDialog,Init(BreakpointCollection,
            CurrentAddress)),nil);
          UpdateViews(cmRedrawCode);
           ClearEvent(Event);
        end;
      cmBreakpoints :
        begin
          ExecuteDialog(New(PBreakpointDialog,Init(BreakpointCollection)),nil);
          UpdateViews(cmRedrawCode);
          ClearEvent(Event);
        end;
      cmGotoCursor :
        begin
          CodeWindow^.Interior^.ChangePC;
          ClearEvent(Event);
        end;
    End;
End; {of TZiLEMApp.HandleEvent}

Var
  ZilemApp : TZilemApp;

Begin
  ZilemApp.Init;
  ZilemApp.Run;
  ZilemApp.Done;
End. {of Program ZiLEM}
