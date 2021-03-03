unit touchrecordfrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    GamePanel: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation


  function isEmpy(Obj: TObject): boolean;
  var
    v: TClass;
  begin
  try
    v:=Obj.ClassParent;
    isEmpy:=false;
  except
    isEmpy:=true;
  end;
end;



{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
const
  // Наибольшие размеры комнат
  xROOM_WIDTH = 20;           // 20 мест по ширине комнаты
  xROOM_HEIGHT = 120;          // 20 мест по высоте комнаты
type
  TxPlaceAbsNum = 1..(xROOM_WIDTH*xROOM_HEIGHT); // abs room-index
  TxPlace = record
    xPicIndex: Integer;       // index of TPictureCache
  end;
  TxRoom = array[TxPlaceAbsNum] of TxPlace; // a hole room
var
  i: Integer;
  w,h: Integer;

  xMyRoomPic: record   // user view
    xRoom: TxRoom;       // room actually viewed
    xPicture: TBitmap;  // paint cache
  end;

begin
  // Показываем размеры комнаты
  Caption:=IntToStr(xROOM_WIDTH)+'*'+IntToStr(xROOM_HEIGHT)+'='+IntToStr(xROOM_WIDTH*xROOM_HEIGHT);
  // Инициируем комнату
  for i := 1 to xROOM_WIDTH*xROOM_HEIGHT do
  begin
    xMyRoomPic.xRoom[i].xPicIndex := -1;
  end;
  // Показываем размеры игрового поля
  Caption:=Caption +' '+IntToStr(GamePanel.ClientWidth)+'*'+IntToStr(GamePanel.ClientHeight)+
    '='+IntToStr(GamePanel.ClientWidth*GamePanel.ClientHeight);
  w := GamePanel.ClientWidth div xROOM_WIDTH;
  h := GamePanel.ClientHeight div xROOM_HEIGHT;

  xMyRoomPic.xPicture := TBitmap.Create();
  //if xMyRoomPic.xPicture <> nil then xMyRoomPic.xPicture.Free();
  try
    if isEmpy(xMyRoomPic.xPicture) then xMyRoomPic.xPicture.Free();
  except
    self.Caption:='Urra!';
  end;
  //if assigned(xMyRoomPic.xPicture) then xMyRoomPic.xPicture.Free();
  {
  xMyRoomPic.Picture := TBitmap.Create();
  xMyRoomPic.Picture.Width := w*xROOM_WIDTH;
  xMyRoomPic.Picture.Height := h*xROOM_HEIGHT;
  }
  //Caption:=Caption +' w='+IntToStr(w)+' h='+IntToStr(h)+': '+
  //  IntToStr(xMyRoomPic.Picture.Width)+'*'+IntToStr(xMyRoomPic.Picture.Height);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  GamePanel.Width:=Form1.Width;
  GamePanel.Height:=Form1.Height;
end;

end.

