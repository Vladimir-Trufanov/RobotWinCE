program robot;

{$mode objfpc}{$H+}

uses
  Interfaces, // this includes the LCL widgetset
  Forms,
  // my stuff
  uMainForm;

begin
  Application.Title:='RobotWinCE';
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

