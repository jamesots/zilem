Program Calculator;

Uses
  App, Objects, Views, Dialogs, Menus, Drivers, Calc;

Const

  {Command constants}

  cmCalc = 1000;

Type

	{Application to encase the calculator for testing.}

  TCalcApp = Object(TApplication)
    Procedure InitStatusLine; virtual;
    Procedure InitMenuBar; virtual;
    Procedure HandleEvent(var Event : TEvent); virtual;
    Procedure ShowCalc;
  end;

{Main application method overriders}

Procedure TCalcApp.InitStatusLine;

Var
  R : TRect;

Begin
  GetExtent(R);
  R.A.Y := R.B.Y-1;
  New(StatusLine, Init(R,
    NewStatusDef(0,$FFFF,
      NewStatusKey('~Alt-C~ Calculator',kbAltC,cmCalc,
      StdStatusKeys(nil)),
    nil)));
End;

Procedure TCalcApp.InitMenuBar;

Var
  R : TRect;

Begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~T~hings',hcNoContext,NewMenu(
      NewItem('~C~alculator','Alt-C',kbAltC,cmCalc,hcNoContext,
      NewLine(
      NewItem('E~x~it','Alt-X',kbAltX,cmQuit,hcNoContext,
      nil)))),
    nil))));
End;

Procedure TCalcApp.HandleEvent(var Event : TEvent);

Begin
  Inherited HandleEvent(Event);
  If (Event.What = evCommand) and (Event.Command = cmCalc) then
    begin
      ShowCalc;
      ClearEvent(Event);
    end;
End;

Procedure TCalcApp.ShowCalc;

Var
  Calculator : PCalc;
  P : TPoint;

Begin
  P.X := 2;
  P.Y := 1;
  New(Calculator,Init(P));
  Desktop^.Insert(Calculator);
End;

{Instance of application object}

Var
  CalcApp : TCalcApp;

{Main program}

Begin
  CalcApp.Init;
  CalcApp.Run;
  CalcApp.Done;
End.
