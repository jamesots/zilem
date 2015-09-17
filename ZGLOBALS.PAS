Unit ZGlobals;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#           Globals            #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Uses
  Objects, Menus, App, ZConsts, Memory;

Const
  HexDigits = '0123456789ABCDEF';
  MemorySize = $FFFF;

Type
  PInteger = ^Integer;

  PZiLEMStatusLine = ^TZiLEMStatusLine;
  TZiLEMStatusLine = Object(TStatusLine)
    Function Hint(AHelpCtx : Word) : String; virtual;
  End;

  TPrefs = record
    ScreenSize : Integer;
    Base : Integer;
    Prefs : Integer;
  end;

Var
  CurrentAddress : Word;
  CurrentPos : Integer;
  Address : Record
    Start, Finish : Word;
  End;
  Pref : TPrefs;
  Clip : Record
    Data : Pointer;
    LastByte : Byte;
    Big : Boolean;
    Size : Word;
  End;
  SearchInfo : Record
    Replace : Boolean;
    FindString,ReplaceString : String;
  End;

Function UnformatStr(S : String; var Error : Boolean) : String;

Implementation

Function UnformatStr(S : String; var Error : Boolean) : String;

Var
  MyStr : String;

Function Convert(S : String; var Error : Boolean) : String;

Var
  Converted : String;
  i : Integer;

Function Quote(var S : String; var Error : Boolean) : String;

Var
  Converted : String;
  EndQuote : Boolean;

Begin
  Converted := '';
  EndQuote := False;
  While (S<>'') and not Error and not EndQuote do
    Begin
      if S[1]=#39 then
        Begin
          If length(S)>1 then
            Begin
              If S[2]=#39 then
                Converted := Converted+#39 else
                EndQuote := True;
              S := Copy(S,2,Length(S)-1);
            End else
            Begin
              EndQuote := True;
              S := ''
            End;
        End else
        Begin
          Converted := Converted + S[1];
          S := Copy(S,2,Length(S)-1);
        End;
    End;
  Quote := Converted;
End; {of UnformatStr|Convert|Quote}

Function Hash(var S : String; var Error : Boolean) : String;

Var
  Converted : String;
  i,ii,code : Integer;

Begin
  Converted := '';
  If S<>'' then
    Begin
      Val(S,i,ii);
      If ii>0 then
        Begin
          Val(Copy(S,1,Pred(ii)),i,code);
          Converted := char(i);
          S := Copy(S,ii,Length(S)-Pred(ii));
        End else
        Begin
          Converted := char(i);
          S := '';
        End;
    End else
    Error := True;
  Hash := Converted;
End; {of UnformatStr|Convert|Hash}

Begin
  Converted := '';
  While (S<>'') and not Error do
    Case S[1] of
      '+' : S := Copy(S,2,Length(S)-1);
      #39 : Begin
              S := Copy(S,2,Length(S)-1);
              Converted := Converted + Quote(S,Error);
            End;
      '#' : Begin
              S := Copy(S,2,Length(S)-1);
              Converted := Converted + Hash(S,Error);
            End;
    Else Error := True;
    End;
  Convert := Converted;
End; {of UnformatStr|Convert}

Begin
  MyStr := S;
  UnformatStr := Convert(MyStr,Error);
End; {of UnformatStr}

Function TZiLEMStatusLine.Hint(AHelpCtx : Word) : String;

Begin
  Case AHelpCtx of
    hcFile : Hint := 'File management commands';
    hcLoad : Hint := 'Load a file into memory';
    hcSaveAs : Hint := 'Save a section of memory to file';
    hcChangeDir : Hint := 'Choose a new default directory';
    hcPrint : Hint := 'Print a section of memory in Hex or ASCII';
    hcDosShell : Hint := 'Temporarily exit to DOS';
    hcQuit : Hint := 'Exit ZiLEM';
    hcEdit : Hint := 'Memory editing commands';
    hcFill : Hint := 'Fill a section of memory with a byte';
    hcCopy : Hint := 'Copy a section of memory to the clipboard';
    hcPaste : Hint := 'Copy memory from the clipboard';
    hcSearch : Hint := 'Search commands';
    hcFind : Hint := 'Search for a byte pattern';
    hcReplace : Hint := 'Search for a byte pattern and replace with a'+
      ' different pattern';
    hcSearchAgain : Hint := 'Repeat previous search';
    hcGoto : Hint := 'Go to a memory location';
    hcRunMenu : Hint := 'Execute or step through a program';
    hcRun : Hint := 'Execute a program';
    hcStep : Hint := 'Execute an instruction; do not trace into calls';
    hcTrace : Hint := 'Execute and instruction; trace into calls';
    hcGoToCursor : Hint := 'Set PC to address of cursor';
    hcInterrupts : Hint := 'Change interrupt mode/send and interrupt';
    hcMode : Hint := 'Change interrupt mode';
    hcInterrupt : Hint := 'Send an interrupt (Use both shift keys when '+
      'running)';
    hcNMI : Hint := 'Send a non-maskable interrupt (Use ctrl and both '+
      'shifts when running)';
    hcDebug : Hint := 'Watches, breakpoints and debugging windows';
    hcBreakpoints : Hint := 'Display current breakpoints';
    hcRegister : Hint := 'Open CPU Register window';
    hcWatch : Hint := 'Open watches window';
    hcUserScreen : Hint := 'Switch to full screen user output - press'+
      ' any key to return to here';
    hcAddWatch : Hint := 'Adds a new watch';
    hcAddBreakpoint : Hint := 'Adds a new breakpoint';
    hcOptions : Hint := 'Changes the ZiLEM defaults';
    hcTerminal : Hint := 'Change the default terminal emulator';
    hcColours : Hint := 'Customize the ZiLEM colours';
    hcPreferences : Hint := 'Change the default base and display options';
    hcOptionsOpen : Hint := 'Load options settings from a file';
    hcOptionsSave : Hint := 'Save the current options settings';
    hcOptionsSaveAs : Hint := 'Save the current options setting to '+
      'another file';
    hcWindow : Hint := 'Arrange windows';
    hcResize : Hint := 'Change the size or position of the active window';
    hcZoom : Hint := 'Enlarge or restore the size of the active window';
    hcNext : Hint := 'Make the next window active';
    hcPrev : Hint := 'Make the previous window active';
    hcClose : Hint := 'Close the active window';
    hcHelp : Hint := 'Get online help';
    hcIndex : Hint := 'Show the index for online help';
    hcTopic : Hint := 'Display help on the word at the cursor';
    hcPreviousTopic : Hint := 'Redisplay the last-viewed help screen';
    hcUsing : Hint := 'How to use ZiLEM';
    hcZ80 : Hint := 'Show information on Z80 instructions';
    hcAbout : Hint := 'Show version and copyright information';

    hcOkButton : Hint := 'Accept the setting in this dialog box';
    hcCancelButton : Hint := 'Close the dialog box without making any'+
      ' changes';
    hcRevertButton : Hint := 'Return to the original directory';
    hcChangeDirButton : Hint := 'Change to the specified directory';

    hcFillFromInputLine : Hint := 'Enter address to start filling from';
    hcFillToInputLine : Hint := 'Enter address to stop filling at';
    hcFillWithInputLine : Hint := 'Enter a byte value to fill with';
    hcGotoInputLine : Hint := 'Enter address to go to';
    hcLoadInputLine : Hint := 'Enter address to load at';
    hcFileInputLine : Hint := 'Enter directory path and file mask';
    hcDirInput : Hint := 'Enter drive and/or directory path';
    hcSaveFromInputLine : Hint := 'Enter address to start saving from';
    hcSaveToInputLine : Hint := 'Enter address to stop saving at';
    hcCopyFromInputLine : Hint := 'Enter address to start copying from';
    hcCopyToInputLine : Hint := 'Enter address to finish copying at';
    hcPasteInputLine : Hint := 'Enter address to paste to';
    hcFindInputLine : Hint := 'Enter string to search for in single'+
      ' quotes';
    hcReplaceInputLine : Hint := 'Enter string to replace with which'+
      ' must be the same length';

    hcFileList : Hint := 'Type for incremental search: lower for files,'+
      ' upper for directories';
    hcDirList : Hint := 'Use cursor keys to navigate through directory'+
      ' tree';

    hcDefaultBaseHexRadio : Hint := 'Enter addresses and Z80 code in'+
      ' hexadecimal';
    hcDefaultBaseDecimalRadio : Hint := 'Enter adresses and Z80 code in'+
      ' decimal';

    hcPrefDisplayCheck : Hint := 'Display characters in the range'+
      ' #00-#1F in the memory window';
    hcPrefPrintCheck : Hint := 'Print characters in the range #80-#FF';
    hcPrefUpperCheck : Hint := 'Display Z80 instructions in upper case';
    hcPrefFollowCheck : Hint := 'Display the Z80 instruction currently'+
      ' being executed';

    hcScreen24Radio : Hint := 'Use a display of 25 lines by 80 columns';
    hcScreen4350Radio : Hint := 'Display 43 lines by 80 columns (EGA) or'+
      ' 50 lines by 80 columns (VGA)';

    hcCodeInputLine : Hint := 'Enter a Z80 mnemonic';
    hcEnterButton : Hint := 'Updates the Z80 memory permanently';
    hcFinishButton : Hint := 'Finish entering Z80 mnemonics';
    hcCodeAddress : Hint := 'Enter the address to store the Z80 code at';

    hcRedrawCode : Hint := 'Redraws the Z80 Code and CPU windows';

    hcInterruptInput : Hint := 'Enter a single byte opcode (Mode 0) or'+
      ' an interrupt offset (Mode 2)';

    hcInterruptMode0Radio : Hint := 'Mode 0 interrupts';
    hcInterruptMode1Radio : Hint := 'Mode 1 interrupts';
    hcInterruptMode2Radio : Hint := 'Mode 2 interrupts';

    hcKindAddressRadio : Hint := 'Watch the address given above';
    hcKindBCRadio : Hint := 'Watch the address given by the BC register';
    hcKindDERadio : Hint := 'Watch the address given by the DE register';
    hcKindHLRadio : Hint := 'Watch the address given by the HL register';
    hcKindIXRadio : Hint := 'Watch the address given by the IX register';
    hcKindIYRadio : Hint := 'Watch the address given by the IY register';
    hcKindSPRadio : Hint := 'Watch the address given by the SP register';
    hcKindPCRadio : Hint := 'Watch the address given by the PC register';

    hcKindInputLine : Hint := 'Enter an address to watch';

    hcPrintFromInputLine : Hint := 'Enter address to start printing at';
    hcPrintToInputLine : Hint := 'Enter address to stop printing at';
    hcPrintHexRadio : Hint := 'Print using the hexadecimal format';
    hcPrintASCIIRadio : Hint := 'Print in ASCII';

    hcCode : Hint := 'Display the Z80 code window';
    hcShowRegisters : Hint := 'Display the Z80 CPU Registers';
    hcShowMemory : Hint := 'Display the Z80 Memory';

    hcBreakpointListBox : Hint := 'Select the breakpoint you wish to remove';
    hcAddBreakpointButton : Hint := 'Adds breakpoint';
    hcRemoveBreakpointButton : Hint := 'Removes selected breakpoint';
    hcBreakpointInputLine : Hint := 'Enter the address of the breakpoint';
    hcPasscountInputLine : Hint := 'Enter a passcount value.';

  else Hint := '';
  end;
End; {of TZiLEMStatusLine.Hint}

Begin
  CurrentAddress := 0;
  CurrentPos := 0;
  With Address do
    Begin
      Start := 0;
      Finish := MemorySize;
    End;
  With Pref do
    Begin
      ScreenSize := 0;
      Base := 0;
      Prefs := 1+8;
    End;
  With Clip do
    Begin
      Size := 0;
      GetMem(Data,Size);
    End;
  With SearchInfo do
    Begin
      Replace := False;
      FindString := '';
      ReplaceString := '';
    End;
End. {of Unit ZGlobals}
