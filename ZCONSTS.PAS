Unit ZConsts;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#          Constants           #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Const

  {Command constants}

  cmLoad = 1000;
  cmPrint = 1001;
  cmFill = 1002;
  cmFind = 101;
  cmReplace = 102;
  cmSearchAgain = 103;
  cmGoto = 104;
  cmRun = 1008;
  cmStep = 1009;
  cmTrace = 1010;
  cmGoToCursor = 105;
  cmMode = 1012;
  cmInterrupt = 100;  {DI disables this one}
  cmNMI = 1013;
  cmBreakpoints = 1014;
  cmRegister = 1015;
  cmWatch = 1016;
  cmUserScreen = 1018;
  cmAddWatch = 1019;
  cmAddBreakpoint = 1020;
  cmTerminal = 1021;
  cmColours = 1022;
  cmPreferences = 1023;
  cmOptionsOpen = 1024;
  cmOptionsSave = 1025;
  cmOptionsSaveAs = 1026;
  cmIndex = 1027;
  cmTopic = 1028;
  cmPreviousTopic = 1029;
  cmUsing = 1030;
  cmZ80 = 1031;
  cmAbout = 1032;
  cmUpdateMemoryPos = 1033;
  cmRedrawMemory = 1034;
  cmModeChanged = 1035;
  cmRedrawCode = 1003;
  cmChangedPC = 1036;
  cmEnterCode = 1037;
  cmRedrawCommand = 1038;
  cmDeleteWatch = 1039;
  cmAssemble = 1040;
  cmCode = 1007;
  cmShowRegisters = 1041;
  cmShowMemory = 1042;
  cmEnterBreakpoint = 1011;
  cmRemoveBreakpoint = 1005;
  cmRedrawAll = 1004;

{Highest cm constant = 1042, gaps = 1006
 Highest cm constant = 104, gaps =}

  {Help Context constants}

  hcFile = 1034;
  hcLoad = 1000;
  hcPrint = 1001;
  hcQuit = 1043;
  hcEdit = 1035;
  hcFill = 1002;
  hcSearch = 1036;
  hcFind = 1004;
  hcReplace = 1005;
  hcSearchAgain = 1006;
  hcGoto = 1007;
  hcRunMenu = 1037;
  hcRun = 1008;
  hcStep = 1009;
  hcTrace = 1010;
  hcGoToCursor = 1011;
  hcInterrupts = 1038;
  hcMode = 1012;
  hcInterrupt = 1033;
  hcNMI = 1013;
  hcDebug = 1039;
  hcBreakpoints = 1014;
  hcRegister = 1015;
  hcWatch = 1016;
  hcUserScreen = 1018;
  hcAddWatch = 1019;
  hcAddBreakpoint = 1020;
  hcOptions = 1040;
  hcTerminal = 1021;
  hcColours = 1022;
  hcPreferences = 1023;
  hcOptionsOpen = 1024;
  hcOptionsSave = 1025;
  hcOptionsSaveAs = 1026;
  hcWindow = 1041;
  hcHelp = 1042;
  hcIndex = 1027;
  hcTopic = 1028;
  hcPreviousTopic = 1029;
  hcUsing = 1030;
  hcZ80 = 1031;
  hcAbout = 1032;
  hcGotoInputLine = 1044;
  hcOkButton = 1045;
  hcCancelButton = 1046;
  hcFillFromInputLine = 1047;
  hcFillToInputLine = 1048;
  hcFillWithInputLine = 1049;
  hcFileInputLine = 1050;
  hcFileList = 1051;
  hcLoadInputLine = 1052;
  hcHelpButton = 1053;
  hcDirInput = 1054;
  hcDirList = 1055;
  hcChangeDirButton = 1056;
  hcRevertButton = 1057;
  hcSaveFromInputLine = 1058;
  hcSaveToInputLine = 1059;

  hcDefaultBaseRadio = 1060;
  hcDefaultBaseHexRadio = 1060;
  hcDefaultBaseDecimalRadio = 1061;

  hcPrefChecks = 1062;
  hcPrefDisplayCheck = 1062;
  hcPrefPrintCheck = 1063;
  hcPrefUpperCheck = 1064;
  hcPrefFollowCheck = 1065;

  hcCopyFromInputLine = 1003;
  hcCopyToInputLine = 1066;
  hcPasteInputLine = 1067;

  hcScreenRadio = 1068;
  hcScreen24Radio = 1068;
  hcScreen4350Radio = 1069;

  hcFindInputLine = 1070;

  hcReplaceInputLine = 1071;

  hcCodeInputLine = 1072;
  hcEnterButton = 1073;
  hcFinishButton = 1074;
  hcCodeAddress = 1075;

  hcRedrawCode = 1076;
  hcInterruptInput = 1077;
  hcInterruptModeRadio = 1078;
  hcInterruptMode0Radio = 1078;
  hcInterruptMode1Radio = 1079;
  hcInterruptMode2Radio = 1080;

  hcKindRadio = 1083;
  hcKindAddressRadio = 1083;
  hcKindBCRadio = 1084;
  hcKindDERadio = 1085;
  hcKindHLRadio = 1086;
  hcKindIXRadio = 1087;
  hcKindIYRadio = 1088;
  hcKindSPRadio = 1089;
  hcKindPCRadio = 1090;
  hcKindInputLine = 1082;

  hcPrintFromInputLine = 1092;
  hcPrintToInputLine = 1093;
  hcPrintRadio = 1094;
  hcPrintHexRadio = 1094;
  hcPrintASCIIRadio = 1095;

  hcCode = 1096;
  hcShowRegisters = 1097;
  hcShowMemory = 1098;

  hcSaving = 10003;
  hcLoading = 10004;
  hcFilling = 10005;
  hcCopying = 10006;
  hcPasting = 10007;

  hcWatchWindow = 10000;
  hcCodeWindow = 10001;
  hcHexWindow = 10002;
  
  hcAddBreakpointButton = 1091;
  hcBreakpointInputLine = 1081;
  hcPasscountInputLine = 1099;

  hcBreakpointListBox = 1100;
  hcRemoveBreakpointButton = 1102;

{highest hc constant = 1102, gaps = 1101}

  {History constants}

  hsChDir = 0;
  hsLoad = 1;
  hsSave = 2;
  hsFindInputLine = 3;
  hsReplaceFindInputLine = 4;
  hsReplaceInputLine = 5;
  hsCodeInputLine = 6;

{highest hs constant = 6, gaps = ()}

  {Terminal status constants}

  teOk = 0;
  teEscape = 1;
  tePositionColumn = 2;
  tePositionRow = 3;

{highest te constant = 3, gaps = ()}

  {Terminal mode constants}

  tmZiLEM = 0;
  tmZ80 = 1;

{highest tm constant = 1, gaps = ()}

  {Execute result constants}

  exOk = 0;
  exHalt = 1;
  exBreak = 2;
  exInt = 3;
  exNMI = 4;
  exStop = 5;
  exUserHalt = 6;

{highest ex constant = 4, gaps = ()}

  {Watch kind constants}
  
  wtAddress = 1;
  wtBC = 2;
  wtDE = 3;
  wtHL = 4;
  wtIX = 5;
  wtIY = 6;
  wtSP = 7;
  wtPC = 8;
  
{highest wt constant = 8, gaps = (0)}

	coBreakpointExists = -3;

Implementation

End.
