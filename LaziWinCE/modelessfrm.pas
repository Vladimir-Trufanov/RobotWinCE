unit ModeLessFrm;

{$mode objfpc}

interface

uses
      Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls;

type

			{ TfrmModeless }

      TfrmModeless = class(TForm)
						ListView1: TListView;
      private

      public

      end;

var
      frmModeless: TfrmModeless;

implementation

{$R *.lfm}

end.

