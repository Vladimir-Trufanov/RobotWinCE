unit LaziWinCEfrm;

{$mode objfpc}{$H+}

interface

uses
  ModalFrm,ModeLessFrm,
  Windows,Math,
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

			{ TfrmLaziWinCE }

      TfrmLaziWinCE = class(TForm)
						Button1: TButton;
						Button10: TButton;
						Button11: TButton;
						Button2: TButton;
						Button3: TButton;
						Button4: TButton;
						Button5: TButton;
						Button6: TButton;
						Button7: TButton;
						Button8: TButton;
						Button9: TButton;
						lblInfo: TLabel;
						procedure Button10Click(Sender: TObject);
						procedure Button11Click(Sender: TObject);
      procedure Button1Click(Sender: TObject);
						procedure Button2Click(Sender: TObject);
						procedure Button3Click(Sender: TObject);
						procedure Button4Click(Sender: TObject);
						procedure Button5Click(Sender: TObject);
						procedure Button6Click(Sender: TObject);
						procedure Button7Click(Sender: TObject);
						procedure Button8Click(Sender: TObject);
						procedure Button9Click(Sender: TObject);
						procedure FormCreate(Sender: TObject);
      private

      public

      end;

var
      frmLaziWinCE: TfrmLaziWinCE;
      nStart,nFinish: Integer;
      nStart64,nFinish64: Integer;

implementation

{$R *.lfm}

// Получить наименование каталога,
// с которого запущена программа
function ExePath(): widestring;
var Str: widestring;
  I: Integer;
begin
  Str := ParamStr (0);
  for I := Length (Str) downto 1 do
    if Str[I] = '\' then
    begin
      Str := Copy (Str, 1, I);
      Break;
    end; {if}
  Result := Str;
end; {func ExePath}

procedure DivZir;
var
  nol: double;
begin
  nol:=0;
  nol:=5/nol;
end;

{ TfrmLaziWinCE }

// Показываем текущий каталог
procedure TfrmLaziWinCE.Button1Click(Sender: TObject);
begin
  lblInfo.Caption:='CurrDir: '+GetCurrentDir;
end;

procedure TfrmLaziWinCE.Button10Click(Sender: TObject);
begin
  frmModal.ShowModal
end;

procedure TfrmLaziWinCE.Button11Click(Sender: TObject);
begin
  frmModeLess.Show();
end;

// Завершаем приложение
procedure TfrmLaziWinCE.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

// Показываем наименование каталога, с которого запущена программа
procedure TfrmLaziWinCE.Button3Click(Sender: TObject);
begin
  lblInfo.Caption:=ExePath();
end;

// Пользуем
procedure TfrmLaziWinCE.Button4Click(Sender: TObject);
var
  cCurrDir, c: String;
  F: TSearchREc;
  Fa: Integer;
  selcap: String;
  n: Integer;
begin
  n:=0;
  cCurrDir:=GetCurrentDir;

  Fa := faAnyFile; // атрибуты искомых файлов - любые;
  //If FindFirst(cCurrDir+'\*.*',Fa,F) <> 0 then
  //If FindFirst(cCurrDir+'*.*',Fa,F) <> 0 then
  If FindFirst('\Storage Card\*.*',Fa,F) <> 0 then
  begin
    c:=' Пусто';
	end
  else begin
    c:=' Eсть '+F.Name;
    FindNext(F); c:=c+', '+F.Name;
    FindNext(F); c:=c+', '+F.Name;
    FindNext(F); c:=c+', '+F.Name;
    //AddNewFile(F); // добавляем его характеристики в список (смотри AddNewFile()
    //while FindNext(F) = 0 do  AddNewFile(F); // находим остальные файлы (и папки), пока они есть
	end;
  FindClose(F);
  lblInfo.Caption:='CurrDir: '+cCurrDir+c;



end;

// Показываем разрешение экрана
function GetDisplaySize: TPoint;
begin
  Result.X := GetSystemMetrics (SM_CXSCREEN);
  Result.Y := GetSystemMetrics (SM_CYSCREEN);
end;
procedure TfrmLaziWinCE.Button5Click(Sender: TObject);
var
  oPoint: TPoint;
begin
  oPoint:=GetDisplaySize();
  lblInfo.Caption:=IntToStr(oPoint.X)+'x'+IntToStr(oPoint.Y);
end;

// Показываем 'Всего' и свободную память
procedure TfrmLaziWinCE.Button6Click(Sender: TObject);
var
  MS: TMemoryStatus;
  nAll,nFree: Integer;
begin
  MS.dwLength := SizeOf (TMemoryStatus);
  GlobalMemoryStatus (MS);
  nAll:=Floor((MS.dwTotalPhys/1024)/1024);
  nFree:=Floor((MS.dwAvailPhys/1024)/1024);
  lblInfo.Caption:='Всего: '+IntToStr(nAll)+'Мb  Свободно: '+
    IntToStr(nFree)+'Mb';
end;

// Показываем время, прошедшее с момента запуска приложения
procedure TfrmLaziWinCE.Button7Click(Sender: TObject);
begin
  // Фиксируем относительное время проверки
  nFinish:=GetTickCount;
  lblInfo.Caption:='Прошло: '+IntToStr(nFinish-nStart)+' миллисекунд!';
end;
procedure TfrmLaziWinCE.Button8Click(Sender: TObject);
begin
  // Фиксируем относительное время проверки
  nFinish64:=GetTickCount64;
  lblInfo.Caption:='Прошло: '+IntToStr(nFinish64-nStart64)+' миллисекунд!';
end;

procedure TfrmLaziWinCE.Button9Click(Sender: TObject);
begin
  try
    DivZir;
  except
    frmModeLess.Caption:='Исключение!';
    frmModeLess.Show();
	end;
end;

procedure TfrmLaziWinCE.FormCreate(Sender: TObject);
begin
  {$IFDEF wince}
    //Top:=0; Left:=0;
    //BorderIcons:=[biSystemMenu];
    //BorderStyle:=bsNone;
    //WindowState:=wsFullScreen;
  {$ELSE}
    Top:=32; Left:=32;
  {$ENDIF}
  lblInfo.Top:=0;
  lblInfo.Left:=0;
  LblInfo.Width:=Width;
  // Фиксируем относительное время запуска приложения
  nStart:=GetTickCount;
  nStart64:=GetTickCount64;
end;

end.

