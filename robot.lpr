program robot;

{$mode objfpc}{$H+}

uses
  Interfaces, // this includes the LCL widgetset
  Forms,
  // my stuff
  uMainForm, RobotUtils, ActionsLife, RobotTypes;

begin
			Application.Title:='Robot';
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

