unit RobotTypes;

{$mode objfpc}

interface

uses
      Classes, SysUtils;

const
  // Размер мира игры: 4*5 = 20 комнат
  WORLD_WIDTH = 5;
  WORLD_HEIGHT = 4;
  // Размер каждой комнаты: 20*20=400 мест
  ROOM_WIDTH = 20;
  ROOM_HEIGHT = 20;
type
  // Абсолютные координаты (диапазон номеров комнат) в игровом мире
  TRoomAbsNum = 1..(WORLD_WIDTH*WORLD_HEIGHT);
  // Двумерные координаты игровой комнаты в игровом мире
  TRoomNum = record
    X: 1..WORLD_WIDTH;
    Y: 1..WORLD_HEIGHT;
  end;
  // Двумерные координаты графического элемента в игровой комнате
  TPlaceNum = record
    X: 1..ROOM_WIDTH;
    Y: 1..ROOM_HEIGHT;
  end;
  // Позиция игрока в комнате и его индекс в кэш-массиве графических элементов
  TPlayer = record
    Pos: TPlaceNum;
    PicIndex: Integer; // графический индекс
  end;
  // Пространство игроков
  TPlayerList = array of TPlayer;                    // дин.массив игроков в комнате
  TWorldPlayers = array[TRoomAbsNum] of TPlayerList; // массив всех игроков мира


implementation

end.

