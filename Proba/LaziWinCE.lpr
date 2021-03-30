program LaziWinCE;

{$mode objfpc}{$H+}

uses
      {$IFDEF UNIX}{$IFDEF UseCThreads}
      cthreads,
      {$ENDIF}{$ENDIF}
      Interfaces, // this includes the LCL widgetset
      Forms, LaziWinCEfrm
      { you can add units after this };

{$R *.res}

begin
      RequireDerivedFormResource:=True;
      Application.Scaled:=True;
      Application.Initialize;
			Application.CreateForm(TfrmLaziWinCE, frmLaziWinCE);
      Application.Run;
end.

