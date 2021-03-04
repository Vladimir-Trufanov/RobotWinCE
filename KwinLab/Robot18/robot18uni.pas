unit robot18uni;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs;

type

  { TfrmRobot18 }

  TfrmRobot18 = class(TForm)
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  frmRobot18: TfrmRobot18;

implementation

{$R *.lfm}

{ TfrmRobot18 }

procedure TfrmRobot18.FormCreate(Sender: TObject);
begin
  {$IFDEF win32}
    Caption:='Игра Robot18 Win32';
  {$ELSE}{$IFDEF wince}
    Caption:='Игра Robot18 WinCE6';
  {$ENDIF}{$ENDIF}
end;

end.

