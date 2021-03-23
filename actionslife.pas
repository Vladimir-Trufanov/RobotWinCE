// LAZARUS, WIN10                                       *** ActionsLife.pas ***

// ****************************************************************************
// *        Блок действий и явлений происходящих с игроками в различных       *
// *                            жизненных ситуациях                           *
// ****************************************************************************

//                                                   Автор:       Труфанов В.Е.
//                                                   Дата создания:  23.03.2021
// Copyright © 2021 TVE                              Посл.изменение: 23.03.2021

unit ActionsLife;

{$mode objfpc}

interface

uses
  Classes, SysUtils, Forms,
  RobotTypes,RobotUtils;

// Переместить короля или робота для сближения с главным игроком на 1 позицию
function alMoveKingOrRobots(ppos,newpos:TPlaceNum):TPlaceNum;
// Проверить не произошло ли столкновение главного игрока с королем или
// роботом. Если это произошло то количество жизней главного игрока
// уменьшается на 1. Кроме этого, столкновении с королем отбрасываем главного
// игрока на позицию в комнате 2x2, столкновение с роботом уничтожает робота
{
function alRuninToKingOrRobots(ppos,newpos:TPlaceNum;
  PictureName:string; MyWorldPlayers:TWorldPlayers;
  MyRoomNum:TRoomNum; f:integer; i:integer):Boolean;
}

implementation

// ****************************************************************************
// *                Переместить короля или робота для сближения               *
// *                     с главным игроком на 1 позицию                       *
// ****************************************************************************
function alMoveKingOrRobots(ppos,newpos:TPlaceNum):TPlaceNum;
// ppos - позиция главного игрока
// newpos - позиция другого игрока (короля или робота)
begin
  // Если смещение по горизотали другого игрока от главного игрока
  // больше смещения по вертикали, то перемещаем его по горизонтвли
  if Abs(ppos.X - newpos.X) > Abs(ppos.Y - newpos.Y)
  then begin // move horiz
    if ppos.X > newpos.X
    then newpos.X := newpos.X + 1
    else newpos.X := newpos.X - 1;
  end
  // Иначе перемещаем другого игрока по вертикали
  else begin // move vert
    if ppos.Y > newpos.Y then newpos.Y := newpos.Y + 1
    else newpos.Y := newpos.Y - 1;
  end;
  Result:=newpos;
end;

// ****************************************************************************
// *   Проверить не произошло ли столкновение главного игрока с королем или   *
// *       роботом. Если это произошло то количество жизней главного игрока   *
// * уменьшается на 1. Кроме этого, столкновении с королем отбрасываем главного
// * игрока на позицию в комнате 2x2, столкновение с роботом уничтожает робота
// ****************************************************************************
{
function alRuninToKingOrRobots(ppos,newpos:TPlaceNum;
  PictureName:string; MyWorldPlayers:TWorldPlayers;
  MyRoomNum:TRoomNum; f:integer; i:integer):Boolean;
// ppos - позиция главного игрока
// newpos - позиция другого игрока (короля или робота)
// PictureName - имя файла графического изображения другого игрока
// MyWorldPlayers - текущее положение игроков во всех комнатах мира
// MyRoomNum - номер текущей комнаты
// f - место главного игрока в списке игроков текущей комнаты
// i - место другого игрока в списке игроков текущей комнаты
begin
  Result:=False;
  // Если позиция другого игрока совпала с позицией главного, то
  // уничтожаем другого игрока, а жизнь главного уменьшаем на 1
  if (newpos.X = ppos.X)and(newpos.Y = ppos.Y) then
  begin
    // Если позиция главного игрока совпала с позицией короля, то перемещаем
    // игрока на позицию 2x2 текущей комнаты и выводим одно из трех сообщений
    if PictureName = 'konig.bmp' then
    begin
      PlaySound('konig.wav',MySoundState);
      {
      ShowMsg([
        'Я должен остерегаться этого.',
        'Король меня достал!',
        'Мне нужно как-то его перехитрить.'
      ]);
      }
      MyWorldPlayers[GetAbs(MyRoomNum)][f].Pos := PlaceNum(2,2);
    end
    // Если позиция главного игрока совпала с позицией робота, то уничтожаем
    // робота, и выводим одно из четырех сообщений
    else
    begin
      PlaySound('robot.wav',MySoundState);
      {
      ShowMsg([
        'Меня поймал робот. Надо будет быстрее убегать в следующий раз.',
        'Какой я не ловкий!',
        'Он меня достал.',
        'Очень раздражают эти железяки!'
      ]);
      }
      //RemovePlayer(GetAbs(MyRoomNum),i);
    end;
    // А жизнь главного уменьшаем на 1
    //RemoveLife();
    Result:=True;
  end;
end;
}
end.

// ******************************************************** ActionsLife.pas ***

