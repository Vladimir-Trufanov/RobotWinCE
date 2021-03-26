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
// Переместить короля или робота в другом направлении от сближения с главным
// игроком на 1 позицию, чтобы обойти препятствие
function alMoveKingOrRobotsBack(ppos,newpos:TPlaceNum):TPlaceNum;

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
  // больше смещения по вертикали, то перемещаем его по горизонтали
  if Abs(ppos.X - newpos.X) > Abs(ppos.Y - newpos.Y) then begin
    if ppos.X > newpos.X then newpos.X := newpos.X + 1
    else newpos.X := newpos.X - 1;
  end
  // Иначе перемещаем другого игрока по вертикали
  else begin
    if ppos.Y > newpos.Y then newpos.Y := newpos.Y + 1
    else newpos.Y := newpos.Y - 1;
  end;
  Result:=newpos;
end;
// ****************************************************************************
// *     Переместить короля или робота в другом направлении от сближения      *
// *         с главным игроком на 1 позицию, чтобы обойти препятствие         *
// ****************************************************************************
function alMoveKingOrRobotsBack(ppos,newpos:TPlaceNum):TPlaceNum;
begin
  if Abs(ppos.X - newpos.X) <= Abs(ppos.Y - newpos.Y) then begin
    if ppos.X > newpos.X then newpos.X := newpos.X + 1
    else newpos.X := newpos.X - 1;
  end
  else begin
    if ppos.Y > newpos.Y then newpos.Y := newpos.Y + 1
    else newpos.Y := newpos.Y - 1;
  end;
  Result:=newpos;
end;

end.

// ******************************************************** ActionsLife.pas ***


