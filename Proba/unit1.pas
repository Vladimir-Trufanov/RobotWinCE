unit Unit1;

{$mode objfpc}{$H+}

interface

uses
      Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls;

type

			{ TForm1 }

      TForm1 = class(TForm)
						BitBtn1: TBitBtn;
						Button1: TButton;
						lbl: TLabel;
						procedure Button1Click(Sender: TObject);
						procedure FormCreate(Sender: TObject);
      private

      public

      end;

var
      Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  lbl.Caption:='Current Directory is : '+GetCurrentDir;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Top:=10;
  Left:=10;
end;

end.

