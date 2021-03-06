unit uMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, GraphType, Crt, StrUtils, StdCtrls, ComCtrls, Menus, LCLType
{$IFDEF win32}
  ,MMSystem
{$ENDIF}
  ;
  
const
  PICTURE_SIZE = // picture cache size
{$IFDEF win32}
    65; // windows needs more
{$ELSE}
    30; // i think, it's a good value...
{$ENDIF}
  // Спецификации (пути+имена) файлов основных графических элементов
  BACKGROUND_PIC = 'hinter.bmp';            // заполнитель фона
  ERROR_PIC = 'error.bmp';                  // ошибочный (отсутствующий) элемент
  PLAYER_PICS: array[1..3] of string =
    ('figur.bmp','robot*.bmp','konig.bmp'); // игроки в комнате
  // Размер мира игры: 4*5 = 20 комнат
  WORLD_WIDTH = 5;
  WORLD_HEIGHT = 4;
  // Размер каждой комнаты: 20*20=400 пунктов
  ROOM_WIDTH = 20;
  ROOM_HEIGHT = 20;
  // Число мест в рюкзаке: 10*5=50
  KNAPSACK_WIDTH = 10;
  KNAPSACK_HEIGHT = 5;
  KNAPSACK_MAX = 27; // для совместимости с Robot1 (9*3)
  
  COMPUTERCONTROL_INTERVAL = 750; // timer-interval for computer player control

type
  // Координаты текущей игры ("уровень") в игровом мире
  TRoomNum = record                                      // world coord
    X: 1..WORLD_WIDTH;
    Y: 1..WORLD_HEIGHT;
  end;
  // Координаты игрока в комнате
  TPlaceNum = record                                     // room coord
    X: 1..ROOM_WIDTH;
    Y: 1..ROOM_HEIGHT;
  end;
  // Позиция размещения элемента в массиве
  TPlace = record
    PicIndex: Integer; // index of TPictureCache
  end;
  // Пространство мест в комнате
  TPlaceAbsNum = 1..(ROOM_WIDTH*ROOM_HEIGHT);      // диапазон мест
  TRoom = array[TPlaceAbsNum] of TPlace;           // пространство мест в комнате
  // Пространство комнат в игровом мире
  TRoomAbsNum = 1..(WORLD_WIDTH*WORLD_HEIGHT);     // диапазон номеров комнат
  TWorld = array[TRoomAbsNum] of TRoom;            // пространство комнат в мире
  // Пространство предметов в рюкзаке
  TKnapsackAbsNum = 1..(KNAPSACK_WIDTH*KNAPSACK_HEIGHT); // диапазон
  TKnapsack = array[TKnapsackAbsNum] of TPlace;          // пространство мест
  //
  TPlayer = record
    Pos: TPlaceNum;
    PicIndex: Integer; // index of TPictureCache
  end;
  TPlayerList = array of TPlayer; // dyn array of players in the room
  TWorldPlayers = array[TRoomAbsNum] of TPlayerList; // all players in the world
  // Пространство графических элементов игры
  TPictureCacheItem = record
    FileName: string;             // Спецификация файла элемента
    Picture: TBitmap;             // Растр элемента
    ResizedPicture: TBitmap;      // Растр элемента с измененным размером
  end;
  TPictureCache = array of TPictureCacheItem; // Пространство элементов

  TMoveDirection = (mdLeft, mdRight, mdUp, mdDown);

  TFocus = (fcRoom, fcKnapsack);

  TDiamondSet = record
    DiamondNr: Integer
  end;

  { TMainForm }

  TMainForm = class(TForm)
    GamePanel: TPanel;
    KnapsackPanel: TPanel;
    InfoPanel: TPanel;
    mnuEditorSave: TMenuItem;
    mnuEditorMode: TMenuItem;
    mnuEditorLoad: TMenuItem;
    mnuEditor: TMenuItem;
    mnuOptionsPause: TMenuItem;
    mnuOptionsSound: TMenuItem;
    mnuOptions: TMenuItem;
    mnuHelpAbout: TMenuItem;
    mnuHelpControl: TMenuItem;
    mnuHelp: TMenuItem;
    mnuHelpDescription: TMenuItem;
    MessageBar: TLabel;
    LifeLabel: TLabel;
    MainMenu: TMainMenu;
    mnuGameEnd: TMenuItem;
    mnuGameLoad: TMenuItem;
    mnuGameNew: TMenuItem;
    mnuGame: TMenuItem;
    OpenGameDialog: TOpenDialog;
    OpenWorldDialog: TOpenDialog;
    SaveGameDialog: TSaveDialog;
    SaveWorldDialog: TSaveDialog;
    ScoresLabel: TLabel;
    DiamondsLabel: TLabel;
    ComputerPlayer: TTimer;
    // event handlers
    procedure ComputerPlayerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure GamePanelClick(Sender: TObject);
    procedure GamePanelMouseDown(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GamePanelMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure KnapsackPanelClick(Sender: TObject);
    procedure KnapsackPanelMouseDown(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
		procedure MessageBarClick(Sender: TObject);
    procedure mnuEditorLoadClick(Sender: TObject);
    procedure mnuEditorModeClick(Sender: TObject);
    procedure mnuEditorSaveClick(Sender: TObject);
    procedure mnuGameEndClick(Sender: TObject);
    procedure mnuGameLoadClick(Sender: TObject);
    procedure mnuGameNewClick(Sender: TObject);
    procedure mnuHelpAboutClick(Sender: TObject);
    procedure mnuHelpControlClick(Sender: TObject);
    procedure mnuHelpDescriptionClick(Sender: TObject);
    procedure mnuOptionsPauseClick(Sender: TObject);
    procedure mnuOptionsSoundClick(Sender: TObject);
  private
    { private declarations }
  public
    nEntry: integer;
    // Игровой мир
    MyWorld: TWorld; // the world
    //
    MyWorldPlayers: TWorldPlayers; // all players
    //
    MyRoomNum: TRoomNum; // selected room of my world
    // Текущее состояние игровой комнаты: Room - позиционный список графических
    // элементы на карте игровой комнаты, Picture - изображение комнаты
    // максимально возможный размера в пикселах
    MyRoomPic: record    // user view
      Room: TRoom;       // room actually viewed
      Picture: TBitmap;  // paint cache
    end;
    //
    MyKnapsack: TKnapsack; // the knapsack
    MyEditorKnapsack: TKnapsack; // the knapsack used in editor mode
    // Текущее содержимое рюкзака игрока
    MyKnapsackPic: record // user view
      Knapsack: TKnapsack; // knapsack actually viewed
      Selection: TKnapsackAbsNum; // selection act viewed
      Picture: TBitmap; // paint cache
    end;
    MyKnapsackSelection: TKnapsackAbsNum; // selected item in the knapsack
    MyFocus: TFocus;
    // Массив загруженных графических элементов игры
    MyPictureCache: TPictureCache; // cache of all graphics in the game
    //
    MyLife: Integer; // lifes
    MyScores: Integer; // scores
    MyDiamonds: array of TDiamondSet; // set diamoonds

    MyPauseState: boolean; // true -> игра поставлена на паузу
    MySoundState: boolean; // false -> звук выключен
    MyEditorMode: boolean; // true -> игра в режиме редактирования

    // gameplay
    function MoveToRoom(dir: TMoveDirection): boolean; // goto next room; return true, if succ
    function MoveToRoom(rnum: TRoomNum): boolean; // goto another room
    procedure MoveToPlace(dir: TMoveDirection); // move player
    function GetMainPlayerIndex(): Integer; // searchs the player; returns -1, if not found
    procedure KillRobots(); // kill all robots in act room
    procedure UseKnapsackSelection();
    procedure ControlComputerPlayers(); // make 'intelligent' movements of all robots and the king
    
    // background stuff
    procedure InitGame();
    procedure RestartGame();
    procedure UnInitGame();
    procedure ResetRoomPic();     // зачистить изображение текущей комнаты
    procedure ResetKnapsackPic(); // зачистить содержимое рюкзака
    procedure ResetWorld();
    procedure ResetKnapsack();
    procedure DrawRoom();         // updates MyRoomPic and GamePanel
    procedure DrawKnapsack(); // updates MyKnapsackPic and KnapsackPanel
    procedure DrawInfo(); // updates InfoPanel
    procedure ShowMsg(msg: string); // printed on MessageBar
    procedure ShowMsg(msgs: array of string); // like ShowMsg; select randomly a msg
    procedure LoadWorld(fname: string); // loads a hole world (sce-file)
    procedure SaveWorld(fname: string); // saves the hole world
    procedure LoadGame(fname: string); // loads a saved game (included world)
    procedure SaveGame(fname: string); // saves a game
    function ShowLoadGameDialog(): boolean; // returns true, if succ
    function ShowSaveGameDialog(): boolean; // returns true, if succ
    function GetPicture(fname: string): TBitmap; // load picture from cache/disk
    function GetPicture(index: Integer): TBitmap;
    function GetPictureName(index: Integer): string; // returns filename
    function GetPictureCacheIndex(fname: string): Integer;
    procedure ResetPictureResizedCache();
    procedure PlaySound(fname: string); // plays wave-file
    function GetPlace(room: TRoomAbsNum; pos: TPlaceNum): TPlace; // get viewed place (with players)
    function GetPlace(pos: TPlaceNum): TPlace; // get viewed place (with players)
    function GetPlacePicName(pos: TPlaceNum): string; // returns picture filename
    procedure SetPlace(pos: TPlaceNum; p: TPlace); // set room place
    procedure SetPlacePicName(pos: TPlaceNum; pname: string); // sets picture filename
    procedure ResetPlace(pos: TPlaceNum);
    function AddPlayer(room: TRoomAbsNum; pos: TPlaceNum; picindex: Integer): Integer; // returns index
    function AddPlayer(room: TRoomAbsNum; pos: TPlaceNum; picname: string): Integer; // returns index
    procedure RemovePlayer(room: TRoomAbsNum; index: Integer);
    procedure RemovePlayer(room: TRoomAbsNum; pos: TPlaceNum);
    function MovePlayer(oldroom: TRoomAbsNum; oldindex: Integer; newroom: TRoomAbsNum; newpos: TPlaceNum): Integer; // returns new index
    function IsPlayerInRoom(picname: string): boolean;
    procedure ResetPlayerList();
    function IsPosInsideRoom(x,y: Integer): boolean;
    function AddToKnapsack(picindex: Integer): boolean; // returns true, if succ
    function AddToKnapsack(picname: string): boolean; // returns true, if succ
    function IsInKnapsack(picname: string): boolean;
    procedure ChangeKnapsackSelection(dir: TMoveDirection);
    procedure AddScores(num: Integer);
    procedure AddLife();
    function RemoveLife(): boolean; // returns true, if still alive
    procedure SetFocus(f: TFocus);
    procedure ChangeFocus();
    procedure SetPauseState(s: boolean);
    Procedure CopyRect(DstCanvas: TCanvas; const Dest: TRect; SrcCanvas: TCanvas; const Source: TRect);
  end;

  function RoomNum(X,Y: Integer): TRoomNum;
  function PlaceNum(X,Y: Integer): TPlaceNum;
  function Place(picindex: Integer): TPlace;
  function Player(picindex: Integer; pos: TPlaceNum): TPlayer;
  function GetAbs(rnum: TRoomNum): TRoomAbsNum; // coord -> abs index
  function GetAbs(pnum: TPlaceNum): TPlaceAbsNum; // coord -> abs index
  function GetNumR(absnum: TRoomAbsNum): TRoomNum; // abs index -> coord
  function GetNumP(absnum: TPlaceAbsNum): TPlaceNum; // abs index -> coord

var
  MainForm: TMainForm;

implementation

function RoomNum(X,Y: Integer): TRoomNum;
begin
  RoomNum.X := X;
  RoomNum.Y := Y;
end;

function PlaceNum(X,Y: Integer): TPlaceNum;
begin
  PlaceNum.X := X;
  PlaceNum.Y := Y;
end;

function Place(picindex: Integer): TPlace;
begin
  Place.PicIndex := picindex;
end;

function Player(picindex: Integer; pos: TPlaceNum): TPlayer;
begin
  Player.PicIndex := picindex;
  Player.Pos := pos;
end;

function GetAbs(rnum: TRoomNum): TRoomAbsNum;
begin
  GetAbs := (rnum.Y-1)*WORLD_WIDTH + rnum.X;
end;

function GetAbs(pnum: TPlaceNum): TPlaceAbsNum;
begin
  GetAbs := (pnum.Y-1)*ROOM_WIDTH + pnum.X;
end;

function GetNumR(absnum: TRoomAbsNum): TRoomNum;
begin
  GetNumR.X := (absnum-1) mod WORLD_WIDTH + 1;
  GetNumR.Y := (absnum-1) div WORLD_WIDTH + 1;
end;

function GetNumP(absnum: TPlaceAbsNum): TPlaceNum;
begin
  GetNumP.X := (absnum-1) mod ROOM_WIDTH + 1;
  GetNumP.Y := (absnum-1) div ROOM_WIDTH + 1;
end;


{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  nEntry:=0;
  // Выполняем настройки формы
  // ! Anchors=[akTop,akLeft] - привязываемся к левому-верхнему углу экрана
  // ! BiDiMode=bdLeftToRight - обычное чтение слева-направо
  BorderStyle:=bsSizeable; // установили обычное окно Windows
  // ! DesignTimePPI:=120; // через DPI изменили размер элементов???
  Height:=618;             // высота формы от строки заголовка до нижней границы
  KeyPreview:=true;        // обеспечили приход на форму всех событий от клавиш
  Left:=636;               // расстояние от левой границы рабочего стола
  Position:=poDefaultPosOnly;  // Windows определяет начальную позицию формы, ее размеры не изменяются
  Width:=485;
  // Иициируем игру
  InitGame();
  // Устанавливаем фонты сообщений по жизням, игровым очкам, найденным алмазам
  LifeLabel.Font := MainForm.Font;
  ScoresLabel.Font := MainForm.Font;
  DiamondsLabel.Font := MainForm.Font;
  //
  GamePanel.OnPaint := @FormPaint;
  KnapsackPanel.OnPaint := @FormPaint;
  // Инициируем начальное построение элементов формы
  FormResize(MainForm);
end;

procedure TMainForm.ComputerPlayerTimer(Sender: TObject);
begin
  ControlComputerPlayers();
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnInitGame();
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = Ord('P') then
    SetPauseState(not MyPauseState)
  else
    SetPauseState(false);
    
  if not (ssCtrl in Shift) then // TODO: change to: nothing in Shift
  case Key of
  37: // left
  begin
    if MyFocus = fcRoom then MoveToPlace(mdLeft);
    if MyFocus = fcKnapsack then ChangeKnapsackSelection(mdLeft);
  end;
  39: // right
  begin
    if MyFocus = fcRoom then MoveToPlace(mdRight);
    if MyFocus = fcKnapsack then ChangeKnapsackSelection(mdRight);
  end;
  38: // up
  begin
    if MyFocus = fcRoom then MoveToPlace(mdUp);
    if MyFocus = fcKnapsack then ChangeKnapsackSelection(mdUp);
  end;
  40: // down
  begin
    if MyFocus = fcRoom then MoveToPlace(mdDown);
    if MyFocus = fcKnapsack then ChangeKnapsackSelection(mdDown);
  end;
  Ord(' '), 9: // space, tab
  begin
    ChangeFocus();
    DrawRoom();
    DrawKnapsack();
  end;
  13: // enter
  begin
    UseKnapsackSelection();
    SetFocus(fcRoom);
  end;
//  8, 46: // backspace, del
//  begin
//    MyKnapsack[MyKnapsackSelection].PicIndex := GetPictureCacheIndex(BACKGROUND_PIC);
//    DrawKnapsack();
//  end;
  else
//    WriteLn('pressed key: ' + IntToStr(Key));
  end;

  // only allow the following in editor mode
  if MyEditorMode then
  begin
    if ssCtrl in Shift then
    case Key of
    37: // left
      MoveToRoom(mdLeft);
    39: // right
      MoveToRoom(mdRight);
    38: // up
      MoveToRoom(mdUp);
    40: // down
      MoveToRoom(mdDown);
    end;
  end;
end;

procedure TMainForm.FormPaint(Sender: TObject);
begin
  DrawRoom();
  DrawKnapsack();
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  ResetRoomPic();
  ResetPictureResizedCache();
  DrawRoom();
end;

procedure TMainForm.GamePanelClick(Sender: TObject);
begin

end;

procedure TMainForm.GamePanelMouseDown(Sender: TOBject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  gx,gy: Integer;
  w,h: Integer;
  i: Integer;
begin
  // TODO: own procedure for editing
  if MyEditorMode then
  begin
    w := GamePanel.ClientWidth div ROOM_WIDTH;
    h := GamePanel.ClientHeight div ROOM_HEIGHT;
    gx := X div w + 1;
    gy := Y div h + 1;
    if (gx >= 1) and (gx <= ROOM_WIDTH)
    and (gy >= 1) and (gy <= ROOM_HEIGHT) then
    begin
      if (MyKnapsackSelection >= 1) then
      begin
        RemovePlayer(GetAbs(MyRoomNum), PlaceNum(gx,gy));
        if Button = mbLeft then
        begin
          // TODO: own procedure for setting a place (or should SetPlace be modified?)
        
          SetPlace(PlaceNum(gx,gy), MyEditorKnapsack[MyKnapsackSelection]);
          
          // look for players
          for i := Low(PLAYER_PICS) to High(PLAYER_PICS) do
          begin
            if IsWild(GetPictureName(MyEditorKnapsack[MyKnapsackSelection].PicIndex), PLAYER_PICS[i], true) then
            begin // it's a player
              SetPlacePicName(PlaceNum(gx,gy), BACKGROUND_PIC);
              AddPlayer(GetAbs(MyRoomNum), PlaceNum(gx,gy), MyEditorKnapsack[MyKnapsackSelection].PicIndex);
            end;
          end;

        end
        else
          ResetPlace(PlaceNum(gx,gy));
        DrawRoom();
      end;
    end;
  end;
end;

procedure TMainForm.GamePanelMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  Button: TMouseButton;
begin
  // TODO: not very nice
  if ssLeft in Shift then
    Button := mbLeft
  else if ssRight in Shift then
    Button := mbRight
  else if ssMiddle in Shift then
    Button := mbMiddle
  else
    exit;
  GamePanelMouseDown(Sender, Button, Shift, X, Y);
end;

procedure TMainForm.KnapsackPanelClick(Sender: TObject);
begin

end;

procedure TMainForm.KnapsackPanelMouseDown(Sender: TOBject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  kx,ky: Integer;
  w,h: Integer;
begin
  // TODO: own procedure for selection
  w := KnapsackPanel.ClientWidth div KNAPSACK_WIDTH;
  h := KnapsackPanel.ClientHeight div KNAPSACK_HEIGHT;
  kx := X div w + 1;
  ky := Y div h + 1;
  if (kx >= 1) and (kx <= KNAPSACK_WIDTH)
  and (ky >= 1) and (ky <= KNAPSACK_HEIGHT) then
  begin
    MyKnapsackSelection := (ky-1)*KNAPSACK_WIDTH + kx;
    DrawKnapsack();
  end;
end;

procedure TMainForm.MessageBarClick(Sender: TObject);
begin

end;

procedure TMainForm.mnuEditorLoadClick(Sender: TObject);
begin
  // TODO: own function ShowLoadWorldDialog
  if OpenWorldDialog.Execute() then
  if FileExists(OpenWorldDialog.FileName) then
    LoadWorld(OpenWorldDialog.FileName);
end;

procedure TMainForm.mnuEditorModeClick(Sender: TObject);
var
  i: Integer;
begin
  // TODO: SetEditorMode

  MyEditorMode := not MyEditorMode;
  mnuEditorMode.Checked := MyEditorMode;
  
  mnuEditorSave.Enabled := MyEditorMode;
  mnuEditorLoad.Enabled := MyEditorMode;
  
  if MyEditorMode = true then
  begin
    // load everything into MyEditorKnapsack
    // TODO: dynamic loading of dir content
    MyEditorKnapsack[1].PicIndex := GetPictureCacheIndex('hinter.bmp');
    MyEditorKnapsack[5].PicIndex := GetPictureCacheIndex('aetz.bmp');
    MyEditorKnapsack[6].PicIndex := GetPictureCacheIndex('leben.bmp');
    MyEditorKnapsack[7].PicIndex := GetPictureCacheIndex('speicher.bmp');
    MyEditorKnapsack[8].PicIndex := GetPictureCacheIndex('kill.bmp');
    MyEditorKnapsack[9].PicIndex := GetPictureCacheIndex('figur.bmp');
    MyEditorKnapsack[10].PicIndex := GetPictureCacheIndex('konig.bmp');
    for i := 1 to 9 do
    begin
      MyEditorKnapsack[i+10].PicIndex := GetPictureCacheIndex('robot' + IntToStr(i) + '.bmp');
      MyEditorKnapsack[i+20].PicIndex := GetPictureCacheIndex('schl' + IntToStr(i) + '.bmp');
      MyEditorKnapsack[i+30].PicIndex := GetPictureCacheIndex('tuer' + IntToStr(i) + '.bmp');
    end;
    for i := 1 to 3 do
    begin
      MyEditorKnapsack[i+1].PicIndex := GetPictureCacheIndex('wand' + IntToStr(i) + '.bmp');
      MyEditorKnapsack[i+40].PicIndex := GetPictureCacheIndex('diamant' + IntToStr(i) + '.bmp');
      MyEditorKnapsack[i+43].PicIndex := GetPictureCacheIndex('code' + IntToStr(i) + '.bmp');
      MyEditorKnapsack[i+46].PicIndex := GetPictureCacheIndex('punkt' + IntToStr(i) + '.bmp');
    end;
    MyEditorKnapsack[50].PicIndex := GetPictureCacheIndex('punkt4.bmp');
    MyEditorKnapsack[40].PicIndex := GetPictureCacheIndex('punkt5.bmp');
  end
  else // MyEditorMode = false
    SetPauseState(true);

  DrawRoom();
  DrawKnapsack();
end;

procedure TMainForm.mnuEditorSaveClick(Sender: TObject);
begin
  // TODO: own function ShowSaveWorldDialog
  if SaveWorldDialog.Execute() then
  begin
  // TODO: if FileExists(SaveWorldDialog.FileName) then
    SaveWorld(SaveWorldDialog.FileName);
    ShowMessage('Gespeichert.');
  end;
end;

procedure TMainForm.mnuGameEndClick(Sender: TObject);
begin
  MainForm.Close();
end;

procedure TMainForm.mnuGameLoadClick(Sender: TObject);
begin
  ShowLoadGameDialog();
end;

procedure TMainForm.mnuGameNewClick(Sender: TObject);
begin
  RestartGame();
end;

procedure TMainForm.mnuHelpAboutClick(Sender: TObject);
begin
  ShowMessage(
              'Ich wurde programmiert von mir, Albert Zeyer.' + LineEnding +
              LineEnding +
              'Updates und weitere Informationen zu mir:' + LineEnding +
              'www.az2000.de/projects/robot2' + LineEnding +
              LineEnding +
              'Fьr weitere Informationen besucht meine Homepage: www.az2000.de'
              );
end;

procedure TMainForm.mnuHelpControlClick(Sender: TObject);
begin
  ShowMessage(
              'Mit den Pfeiltasten gibst du deinem Kцrper die Anweisung, ' +
              'in die entsprechende Richtung zu gehen. Dieser sammelt dabei ' +
              'automatisch aufsammelbare Gegenstдnde auf (vorausgesetzt, es ' +
              'ist genьgend Platz im Rucksack). Mit Leertaste oder Tab ' +
              'lдsst sich eine Auswahl im Rucksack treffen und mit Enter ' +
              'wird der entsprechend ausgewдhlte Gegenstand benutzt. ' +
              'Mit P gelangst du in den Pause-Modus, in dem die Zeit ' +
              'stillsteht. Wenn du das Verlangen hast, in eine andere Welt ' +
              'abzutauchen, empfiehlt es sich, den Status dieser Robot-Welt ' +
              'zu speichern, indem du ein eingesammeltes Speicherelement ' +
              '(Uhr-Symbol) benutzt, um spдter an dieser Stelle fortfahren ' +
              'zu kцnnen.' + LineEnding +
              LineEnding +
              'Den Rest kriegst du schon selbst raus. In deinen anderen ' +
              'Welten ist das schlieЯlich auch nicht anders.'
              );
end;

procedure TMainForm.mnuHelpDescriptionClick(Sender: TObject);
begin
  ShowMessage(
              'In diesem Spiel geht es darum, das Spiel durchzuspielen und ' +
              'am Ende zum bцsen Kцnig zu gelangen, der um dich daran zu ' +
              'hindern, seine nervigen Roboter ausgesandt hat.' + LineEnding +
              LineEnding +
              'Der Kцnig ist normalerweise unbesiegbar, gдbe es nicht die 3 ' +
              'magischen Diamantenstellen, die nachdem die passenden ' +
              'Diamanten eingesetzt wurden, den Bann der Unbesiegbarkeit ' +
              'brechen und ihn verwundbar machen. Dies war der Preis des ' +
              'Kцnigs fьr seine Unbesiegbarkeit. Um es dir schwer zu machen, ' +
              'wurden diese Diamanten allerdings in den Rдumen verstrдut. ' +
              'Teilweise hat er nachtrдglich auch manche Wege zugemauert, ' +
              'war dabei allerdings sparsam im Material, so dass sich diese ' +
              'Wдnde mit aggresiver Дtzflьssigkeit weg machen lassen.' +
              'Fьr die vielen Tьren lassen sich ьberall in den Rдumen ' +
              'Schlьssel finden, die den Zugang ermцglichen.' + LineEnding +
              LineEnding +
              'Mit der Devise "Es gibt immer einen Weg" lдsst sich der Weg ' +
              'zum Sieg bahnen!'
              );
end;

procedure TMainForm.mnuOptionsPauseClick(Sender: TObject);
begin
  SetPauseState(not mnuOptionsPause.Checked);
end;

procedure TMainForm.mnuOptionsSoundClick(Sender: TObject);
begin
  // TODO: SetSoundState procedure
  MySoundState := not MySoundState;
  mnuOptionsSound.Checked := MySoundState;
end;


// ------------------------------------------------
// gameplay

function TMainForm.MoveToRoom(rnum: TRoomNum): boolean;
begin
  // TODO: same reaction like other MoveToRoom
  // (it only works now, because this function is not used in main context)
  MyRoomNum := rnum;
  MoveToRoom := true;
  if MoveToRoom then DrawRoom();
end;

function TMainForm.MoveToRoom(dir: TMoveDirection): boolean;
var
  i: Integer;
  s: string;
begin
  // could I really go?
  // TODO: special function for this
  // everything is allowed in editor mode, even this
  // if the player is not here, give the ability to search him
  if (not MyEditorMode) and (GetMainPlayerIndex() >= 0) then
  begin
    for i := Low(MyWorldPlayers[GetAbs(MyRoomNum)]) to High(MyWorldPlayers[GetAbs(MyRoomNum)]) do
    begin
      s := GetPictureName(MyWorldPlayers[GetAbs(MyRoomNum)][i].PicIndex);
      if (IsWild(s, 'robot*.bmp', false))
      or (s = 'konig.bmp') then
      begin // don't leave, if any robot is alive!
        MoveToRoom := false;
        ShowMsg([
                 'Da krabbeln noch so Dinger rum.',
                 'Es bewegt sich noch etwas.',
                 'Der Raum bleibt abgeschlossen.',
                 'Ich kann nicht einfach so gehen.',
                 'So lange lebende Roboter hier drin sind, geht das nicht.'
                 ]);
        exit;
      end;
    end;
  end;
  
  MoveToRoom := true;
  case dir of
  mdLeft:
    if MyRoomNum.X > 1 then MyRoomNum.X := MyRoomNum.X - 1
    else MoveToRoom := false;
  mdRight:
    if MyRoomNum.X < WORLD_WIDTH then MyRoomNum.X := MyRoomNum.X + 1
    else MoveToRoom := false;
  mdUp:
    if MyRoomNum.Y > 1 then MyRoomNum.Y := MyRoomNum.Y - 1
    else MoveToRoom := false;
  mdDown:
    if MyRoomNum.Y < WORLD_HEIGHT then MyRoomNum.Y := MyRoomNum.Y + 1
    else MoveToRoom := false;
  end;

  if MoveToRoom then
  begin
    if IsPlayerInRoom('konig.bmp') then
      ComputerPlayer.Interval := COMPUTERCONTROL_INTERVAL div 2
    else
      ComputerPlayer.Interval := COMPUTERCONTROL_INTERVAL;
      
    DrawRoom();
  end;
end;

function TMainForm.GetMainPlayerIndex(): Integer;
var
  i: Integer;
begin
  GetMainPlayerIndex := -1;
  if Length(MyWorldPlayers[GetAbs(MyRoomNum)]) > 0 then
  for i := Low(MyWorldPlayers[GetAbs(MyRoomNum)]) to High(MyWorldPlayers[GetAbs(MyRoomNum)]) do
  begin
    if MyWorldPlayers[GetAbs(MyRoomNum)][i].PicIndex = GetPictureCacheIndex('figur.bmp') then
    begin
      GetMainPlayerIndex := i;
      exit;
    end;
  end;
end;

procedure TMainForm.MoveToPlace(dir: TMoveDirection);
var
  f: Integer;
  i: Integer;
  oldroom: TRoomAbsNum;
  oldpos, newpos: TPlaceNum;
begin
  f := GetMainPlayerIndex();
  if f < 0 then
  begin // main player not found
    WriteLn('WARNING: main player not found');
    exit;
  end;

  // calc new pos (or room change)
  oldroom := GetAbs(MyRoomNum);
  oldpos := MyWorldPlayers[GetAbs(MyRoomNum)][f].Pos;
  newpos := oldpos;
  case dir of
  mdLeft:
    if oldpos.X = 1 then // on border
    begin
      if not MoveToRoom(dir) then exit;
      newpos.X := ROOM_WIDTH;
      f := MovePlayer(oldroom, f, GetAbs(MyRoomNum), newpos);
    end
    else
    begin
      newpos.X := oldpos.X - 1;
    end;
  mdRight:
    if oldpos.X = ROOM_WIDTH then // on border
    begin
      if not MoveToRoom(dir) then exit;
      newpos.X := 1;
      f := MovePlayer(oldroom, f, GetAbs(MyRoomNum), newpos);
    end
    else
    begin
      newpos.X := oldpos.X + 1;
    end;
  mdUp:
    if oldpos.Y = 1 then // on border
    begin
      if not MoveToRoom(dir) then exit;
      newpos.Y := ROOM_HEIGHT;
      f := MovePlayer(oldroom, f, GetAbs(MyRoomNum), newpos);
    end
    else
    begin
      newpos.Y := oldpos.Y - 1;
    end;
  mdDown:
    if oldpos.Y = ROOM_HEIGHT then // on border
    begin
      if not MoveToRoom(dir) then exit;
      newpos.Y := 1;
      f := MovePlayer(oldroom, f, GetAbs(MyRoomNum), newpos);
    end
    else
    begin
      newpos.Y := oldpos.Y + 1;
    end;
  end;
  
  // room change? => ignore everything else
  if oldroom <> GetAbs(MyRoomNum) then
  begin
    DrawRoom();
    exit;
  end;
  
  if (GetPlacePicName(newpos) = 'wand1.bmp') // normal wall
  or (GetPlacePicName(newpos) = 'wand2.bmp') // hard wall
  then
  begin
    //ShowMsg([
    //         'Hier geht es nicht weiter.',
    //         'Ich will nicht gegen die Wand laufen.',
    //         'Stop'
    //         ]);
    PlaySound('fl.wav');
    exit;
  end;

  if IsWild(GetPlacePicName(newpos), 'code*.bmp', true) // diamondplace
  then
  begin
    ShowMsg([
             'Ich muss hier den richtigen Diamanten benutzen.',
             'Hierfьr braucht man die Diamanten.',
             'Der Diamantenstellplatz...'
             ]);
    PlaySound('fl.wav');
    exit;
  end;
  
  if GetPlacePicName(newpos) = 'wandEl.bmp' // electric-wall
  then
  begin
    ShowMsg([
             'Aua!',
             'Bzzzz',
             'Deshalb solltet ihr nie in Steckdosen fassen.',
             'Das tut weh!',
             'Da sollte ich nдchstes Mal nicht mehr reinlaufen.'
             ]);
    PlaySound('strom.wav');
    RemoveLife();
    ResetPlace(newpos);
  end;
  
  if IsWild(GetPlacePicName(newpos), 'tuer*.bmp', false) // dor
  then
  begin
    PlaySound('fl.wav');
    if not IsInKnapsack(AnsiReplaceStr(GetPlacePicName(newpos), 'tuer', 'schl')) then
    begin
      ShowMsg([
               'Mir fehlt der Schlьssel.',
               'Der richtige Schlьssel fehlt.',
               'Den Schlьssel hierfьr habe ich noch nicht.',
               'Ich brauche den Schlьssel.'
               ]);
      exit;
    end;
  end;
  
  if IsWild(GetPlacePicName(newpos), 'robot*.bmp', false) // robot
  then
  begin
    ShowMsg([
             'Au, der tut mir weh!',
             'Der ist bцse!',
             'Sehr nervig diese Roboter.',
             'Ich sollte mich demnдchst in Acht nehmen.',
             'Man bin ich blцd, dem Roboter direkt in die Arme gelaufen.'
             ]);
    PlaySound('robot.bmp');
    RemoveLife();
    RemovePlayer(GetAbs(MyRoomNum), newpos);
  end;
  
  if GetPlacePicName(newpos) = 'konig.bmp' // king
  then
  begin
    ShowMsg([
             'Man bin ich blцd, dem Kцnig direkt in die Arme gelaufen.',
             'Der ist stдrker als ich.',
             'Nдchstes Mal besser aufpassen.',
             'Da muss ich mir etwas besseres ausdenken.',
             'Ich jage ihn wohl besser in einen Elektrozaun.'
             ]);
    PlaySound('konig.wav');
    RemoveLife();
    MyWorldPlayers[GetAbs(MyRoomNum)][f].Pos := PlaceNum(2,2);
    DrawRoom();
    exit;
  end;

  if IsWild(GetPlacePicName(newpos), 'punkt*.bmp', false) // scores
  then
  begin
    ShowMsg([
             'Ah, schцn.',
             'Nett!',
             'Wie das funkelt.',
             'Das ist bestimmt viel wert.',
             'Das sieht schick aus!',
             'Oh wie toll!',
             'Guck mal, was ich tolles gefunden habe!',
             'Dafьr kriegt man bestimmt viel Geld.',
             'Ich will mehr!',
             'Von wem das wohl stammt?',
             'Ob ich das zum Fundbьro bringen sollte?',
             'Ich bin ein Glьckspilz.'
             ]);
    PlaySound('punkt.wav');
    AddScores(1000);
    ResetPlace(newpos);
  end;
  
  if GetPlacePicName(newpos) = 'kill.bmp' // robot killer
  then
  begin
    ShowMsg([
             'Sterbt, ihr Roboter!',
             'Das habt ihr nun davon!',
             'So ist das Roboter-Leben.',
             'Wie das wohl funktioniert?'
             ]);
    PlaySound('rl.wav');
    KillRobots();
    f := GetMainPlayerIndex(); // index numbering changed
    ResetPlace(newpos);
  end;

  if (IsWild(GetPlacePicName(newpos), 'schl*.bmp', false)) // key
  or (GetPlacePicName(newpos) = 'leben.bmp') // life
  or (GetPlacePicName(newpos) = 'aetz.bmp') // TODO: aetz?
  or (GetPlacePicName(newpos) = 'speicher.bmp') // saveitem
  then
  begin
    PlaySound('einsatz.wav');
    if AddToKnapsack(GetPlace(newpos).PicIndex) then
    begin
      ShowMsg([
               'Damit kann man sicher tolle Sachen machen.',
               'Das muss ich mir spдter mal genauer ansehen.',
               'Ich nehm das mal mit.'
               ]);
      AddScores(500);
      ResetPlace(newpos);
    end
    else
    begin
      ShowMsg([
               'Wenn mein Rucksack nicht voll wдre, hдtte ich das mitgenommen.',
               'Leider ist mein Rucksack voll.',
               'Ich glaube, ich sollte etwas Platz in meinem Rucksack machen.',
               'Besser ist wohl, ich mache Platz im Rucksack.'
               ]);
    end;
  end;

  if IsWild(GetPlacePicName(newpos), 'diamant*.bmp', false) // diamond
  then
  begin
    PlaySound('punkt.wav');
    if AddToKnapsack(GetPlace(newpos).PicIndex) then
    begin
      ShowMsg([
               'Wow, ein Diamant!',
               'Den muss ich nur noch an die richtige Stelle setzen.',
               'Der muss an die Diamantenstelle!',
               'Den hab ich gesucht!'
               ]);
      AddScores(1000);
      ResetPlace(newpos);
    end
    else
    begin
      ShowMsg([
               'Hierfьr sollte ich auf jeden Fall Platz im Rucksack machen!',
               'Der Platz im Rucksack ist es wert!',
               'Mir fehlt Platz fьr den Diamanten.'
               ]);
    end;
  end;

  MyWorldPlayers[GetAbs(MyRoomNum)][f].Pos := newpos;
  
  DrawRoom();
end;

procedure TMainForm.KillRobots();
var
  i: Integer;
begin
  for i := Low(MyWorldPlayers[GetAbs(MyRoomNum)]) to High(MyWorldPlayers[GetAbs(MyRoomNum)]) do
  begin
    if IsWild(GetPictureName(MyWorldPlayers[GetAbs(MyRoomNum)][i].PicIndex), 'robot*.bmp', false) then // robot
    begin
      RemovePlayer(GetAbs(MyRoomNum), i);
      KillRobots(); // search again because index numbering changed
      exit;
    end;
  end;
end;

procedure TMainForm.UseKnapsackSelection();
var
  s: string;
  f: Integer;
  pos: TPlaceNum;
  tmp: string;
  did: boolean;
  i: Integer;
begin
  s := GetPictureName(MyKnapsack[MyKnapsackSelection].PicIndex);
  
  if s = BACKGROUND_PIC then
  begin
    ShowMsg([
             'Ich muss erst etwas auswдhlen.',
             'Was soll ich benutzen?',
             'Ich kann nicht zaubern.'
             ]);
    exit; // nothing selected
  end;
  if IsWild(s, 'schl*.bmp', false) then
  begin
    ShowMsg([
             'Den brauche ich, um durch Tьren gehen zu kцnnen.',
             'Den muss ich nicht direkt benutzen.',
             'Ich kann damit nichts Besonderes machen - auЯer durch Tьren zu gehen.',
             'Das geht gerade nicht.'
             ]);
    exit; // cannot use key
  end;
  
  f := GetMainPlayerIndex();
  if f < 0 then
  begin
    ShowMsg([
             'Wo bin ich?',
             'Ich sehe nichts.'
             ]);
    exit; // do only things if player is in act room
  end;
  pos := MyWorldPlayers[GetAbs(MyRoomNum)][f].Pos;
  
  if s = 'leben.bmp' then // TODO: lebenselexier?
  begin
    AddLife();

    ShowMsg([
             'Ah, das tat gut.',
             'Lecker!',
             'Man fьhlt sich fast wie neugeboren.'
             ]);
  end;
  
  if IsWild(s, 'diamant*.bmp', false) then // diamond
  begin
    tmp := AnsiReplaceStr(s, 'diamant', 'code');
    did := false;
    if (pos.X >= 2) and (GetPlacePicName(PlaceNum(pos.X-1,pos.Y)) = tmp) then
    begin
      did := true;
      SetPlacePicName(PlaceNum(pos.X-1,pos.Y), BACKGROUND_PIC);
    end
    else if (pos.X <= ROOM_WIDTH-1) and (GetPlacePicName(PlaceNum(pos.X+1,pos.Y)) = tmp) then
    begin
      did := true;
      SetPlacePicName(PlaceNum(pos.X+1,pos.Y), BACKGROUND_PIC);
    end
    else if (pos.Y >= 2) and (GetPlacePicName(PlaceNum(pos.X,pos.Y-1)) = tmp) then
    begin
      did := true;
      SetPlacePicName(PlaceNum(pos.X,pos.Y-1), BACKGROUND_PIC);
    end
    else if (pos.Y <= ROOM_HEIGHT-1) and (GetPlacePicName(PlaceNum(pos.X,pos.Y+1)) = tmp) then
    begin
      did := true;
      SetPlacePicName(PlaceNum(pos.X,pos.Y+1), BACKGROUND_PIC);
    end;

    if not did then
    begin
      ShowMsg([
               'Den Diamanten kann ich nur an der richtigen Stelle einsetzen.',
               'Wo ist die Diamantenstelle?',
               'Ich benцtige eine Diamantenstelle',
               'Was soll ich damit hier tun?'
               ]);
      exit;
    end;

    ShowMsg([
             'Ich glaube, das war sehr gut.',
             'Das funktioniert!',
             'Super!'
             ]);
    SetLength(MyDiamonds, Length(MyDiamonds) + 1);
    with MyDiamonds[High(MyDiamonds)] do
      DiamondNr := StrToInt(AnsiReplaceStr(AnsiReplaceStr(s, 'diamant', ''), '.bmp', ''));
    DrawInfo();
  end;
  
  if s = 'speicher.bmp' then // save-item
  begin
    // have to reset it first, because else, the saved game contains also this save-element
    MyKnapsack[MyKnapsackSelection].PicIndex := GetPictureCacheIndex(BACKGROUND_PIC);
    if not ShowSaveGameDialog() then
    begin
      MyKnapsack[MyKnapsackSelection].PicIndex := GetPictureCacheIndex('speicher.bmp');
      exit;
    end;
  end;
  
  if s = 'aetz.bmp' then // TODO: aetz? (english)
  begin
    did := false;
    if IsPosInsideRoom(pos.X-1,pos.Y) and (GetPlacePicName(PlaceNum(pos.X-1,pos.Y)) = 'wand1.bmp') then
    begin
      did := true;
      SetPlacePicName(PlaceNum(pos.X-1,pos.Y), BACKGROUND_PIC);
    end;
    if IsPosInsideRoom(pos.X+1,pos.Y) and (GetPlacePicName(PlaceNum(pos.X+1,pos.Y)) = 'wand1.bmp') then
    begin
      did := true;
      SetPlacePicName(PlaceNum(pos.X+1,pos.Y), BACKGROUND_PIC);
    end;
    if IsPosInsideRoom(pos.X,pos.Y-1) and (GetPlacePicName(PlaceNum(pos.X,pos.Y-1)) = 'wand1.bmp') then
    begin
      did := true;
      SetPlacePicName(PlaceNum(pos.X,pos.Y-1), BACKGROUND_PIC);
    end;
    if IsPosInsideRoom(pos.X,pos.Y+1) and (GetPlacePicName(PlaceNum(pos.X,pos.Y+1)) = 'wand1.bmp') then
    begin
      did := true;
      SetPlacePicName(PlaceNum(pos.X,pos.Y+1), BACKGROUND_PIC);
    end;
    
    if not did then
    begin
      ShowMsg([
               'Ich kann hier nichts wegдtzen.',
               'Das geht hier nicht.',
               'Was soll ich damit hier tun?',
               'Ist alles schon weg hier.',
               'Hallo?',
               'Wдre bloЯ eine Verschwendung hier'
               ]);
      exit;
    end;

    ShowMsg([
             'Das geht weg wie nix.',
             'Sehr umweltschдdlich!',
             'Trickreich...',
             'Ha, bin ich geschickt :)'
             ]);
    DrawRoom();
  end;
  
  PlaySound('einsatz.wav');
  MyKnapsack[MyKnapsackSelection].PicIndex := GetPictureCacheIndex(BACKGROUND_PIC);

  // search other s in knapsack and select it; else select any other element

  // use variable f now for KnapsackSelectionIndex
  f := 0;
  for i := 1 to KNAPSACK_MAX do
  begin
    if GetPictureName(MyKnapsack[i].PicIndex) = s then
    begin
      f := i;
      break;
    end;
  end;
  if f = 0 then
  for i := 1 to KNAPSACK_MAX do
  begin
    if GetPictureName(MyKnapsack[i].PicIndex) <> BACKGROUND_PIC then
    begin
      f := i;
      break;
    end
  end;
  
  if f <> 0 then
  begin
    // TODO: own function SetKnapsackSelection
    MyKnapsackSelection := f;
  end;

  DrawKnapsack();
end;

procedure TMainForm.ControlComputerPlayers();
var
  f: Integer;
  i: Integer;
  ppos, newpos: TPlaceNum;
  s: string;
begin
  if MyPauseState = true then exit; // don't do anything while pausing
  if MyEditorMode = true then exit; // don't do anything while editing
  
  f := GetMainPlayerIndex();
  if f < 0 then exit; // don't do anything if the player is not here
  
  ppos := MyWorldPlayers[GetAbs(MyRoomNum)][f].Pos;
  
  for i := Low(MyWorldPlayers[GetAbs(MyRoomNum)]) to High(MyWorldPlayers[GetAbs(MyRoomNum)]) do
  begin
    s := GetPictureName(MyWorldPlayers[GetAbs(MyRoomNum)][i].PicIndex);
    if (IsWild(s, 'robot*.bmp', false))
    or (s = 'konig.bmp') then
    begin
      newpos := MyWorldPlayers[GetAbs(MyRoomNum)][i].Pos;
      if Abs(ppos.X - newpos.X) > Abs(ppos.Y - newpos.Y) then
      begin // move horiz
        if ppos.X > newpos.X then
          newpos.X := newpos.X + 1
        else
          newpos.X := newpos.X - 1;
      end
      else
      begin // move vert
        if ppos.Y > newpos.Y then
          newpos.Y := newpos.Y + 1
        else
          newpos.Y := newpos.Y - 1;
      end;
      
      if (newpos.X = ppos.X)
      and (newpos.Y = ppos.Y) then
      begin
        if s = 'konig.bmp' then
        begin
          PlaySound('konig.wav');
          ShowMsg([
                   'Vor dem sollte ich aufpassen.',
                   'Der Kцnig hat mich bekommen!',
                   'Ich muss ihn irgendwie austricksen.'
                   ]);
          MyWorldPlayers[GetAbs(MyRoomNum)][f].Pos := PlaceNum(2,2);
        end
        else
        begin
          PlaySound('robot.wav');
          ShowMsg([
                   'Ein Roboter hat mich erwischt. Nдchstes Mal besser wegrennen.',
                   'Das war ungeschickt.',
                   'Der hat mich erwischt.',
                   'Sehr nervig diese Teile!'
                   ]);
          RemovePlayer(GetAbs(MyRoomNum), i);
        end;
        RemoveLife();
        DrawRoom();
        exit;
      end;
      
      if GetPlacePicName(newpos) = 'wandEl.bmp' then
      begin
        if s = 'konig.bmp' then
        begin
          PlaySound('konig.wav');
          if Length(MyDiamonds) = 3 then
          begin
            RemovePlayer(GetAbs(MyRoomNum), i);
            ShowMsg([
                     'Hurra, der Kцnig ist tot!',
                     'Das Spiel ist gewonnen!',
                     'Toll, ich habe es geschafft!'
                     ]);
            ShowMessage(
                        'Super, du hast es wirklich geschafft, das Ziel des ' +
                        'Spieles, d.h. der dir vorgegebenen Regeln, ist ' +
                        'geschafft! Der Kцnig dieser Robot-Welt wurde ' +
                        'besiegt.' + LineEnding +
                        LineEnding +
                        'Und was sagt uns das? Es gibt immer einen Weg! ' + LineEnding +
                        '(Ьber den Sinn dieses Spieles inklusive seinem Ziel ' +
                        'lдsst sich jetzt streiten, aber du kannst von dir ' +
                        'behaupten, das Ziel trotzdem erreicht zu haben.)' + LineEnding +
                        LineEnding +
                        'Was kommt nun?' + LineEnding +
                        'Tja, das Leben geht weiter; was als nдchstes kommt, ' +
                        'bleibt rein dir ьberlassen.' + LineEnding +
                        'Vielleicht tauchst du jetzt mal wieder in deine ' +
                        'von dir als normal angesehene Welt ab, um dort andere ' +
                        'von dir selbst gestellten Ziele zu erreichen.' + LineEnding +
                        'Vielleicht hast du aber auch Lust, noch andere ' +
                        'Welten zu erforschen, Neues zu lernen und vor allem ' +
                        'einfach nur deine Zeit zu vertreiben. In diesem Fall ' +
                        'kann ich dir einen Besuch meiner Homepage empfehlen.' + LineEnding +
                        LineEnding +
                        '- Albert Zeyer (www.az2000.de/projects)'
                        );
          end
          else // not all diamonds set
          begin
            ShowMsg([
                     'Oh nein, es sind noch nicht alle Diamanten gesetzt!',
                     'Ich muss wohl noch ein Diamanten setzen.',
                     'So wird das nichts.'
                     ]);
          end;
          SetPlacePicName(newpos, BACKGROUND_PIC);
        end
        else // robot
        begin
          PlaySound('rl.wav');
          RemovePlayer(GetAbs(MyRoomNum), i);
          SetPlacePicName(newpos, BACKGROUND_PIC);
        end;
        DrawRoom();
        ControlComputerPlayers(); // index numbering changed
        exit;
      end;
      
      if GetPlace(newpos).PicIndex = GetPictureCacheIndex(BACKGROUND_PIC) then
      begin
        if s = 'konig.bmp' then
          PlaySound('konig.wav')
        else
          PlaySound('rl.wav');
        MyWorldPlayers[GetAbs(MyRoomNum)][i].Pos := newpos;
        DrawRoom();
      end
      else // wall or something else
      begin
        // try other direction
        newpos := MyWorldPlayers[GetAbs(MyRoomNum)][i].Pos;
        if Abs(ppos.X - newpos.X) <= Abs(ppos.Y - newpos.Y) then
        begin // move horiz
          if ppos.X > newpos.X then
            newpos.X := newpos.X + 1
          else
            newpos.X := newpos.X - 1;
        end
        else
        begin // move vert
          if ppos.Y > newpos.Y then
            newpos.Y := newpos.Y + 1
          else
            newpos.Y := newpos.Y - 1;
        end;
        if GetPlace(newpos).PicIndex = GetPictureCacheIndex(BACKGROUND_PIC) then
        begin
          if s = 'konig.bmp' then
            PlaySound('konig.wav')
          else
            PlaySound('rl.wav');
          MyWorldPlayers[GetAbs(MyRoomNum)][i].Pos := newpos;
          DrawRoom();
        end;
      end;
    end;
  end;
end;
// ****************************************************************************
// *                             Инициировать игру                            *
// ****************************************************************************
procedure TMainForm.InitGame(); // start here
var
  tmp: TBitmap;
  i: Integer;
begin
  // Запускаем генерацию псевдослучайностей
  Randomize();
  // Указываем, что звук должен быть выключенным
  MySoundState := false;
  // Зачищаем изображение текущей комнаты
  ResetRoomPic();
  // Зачищаем содержимое рюкзака
  ResetKnapsackPic();
  // Загружаем изображения комнат и запускаем игру
  RestartGame();
end;
// ****************************************************************************
// *                 Загрузить изображения комнат и запустить игру            *
// ****************************************************************************
procedure TMainForm.RestartGame();
begin
  ResetKnapsack();
  LoadWorld('robot.sce');
  MoveToRoom(RoomNum(1,1));

  MyEditorMode := false;

  MyKnapsackSelection := 1;
  MyLife := 3;
  MyScores := 0;
  SetLength(MyDiamonds, 0);
  DrawInfo();

  SetFocus(fcRoom);
  
  DrawRoom();
  DrawKnapsack();
  
  PlaySound('newgame.wav');
  SetPauseState(true);
end;

procedure TMainForm.UnInitGame();
var
  i: Integer;
begin
  for i := Low(MyPictureCache) to High(MyPictureCache) do
  begin
    if MyPictureCache[i].Picture <> nil then
    begin
      MyPictureCache[i].Picture.Free();
      MyPictureCache[i].Picture := nil;
    end;
    if MyPictureCache[i].ResizedPicture <> nil then
    begin
      MyPictureCache[i].ResizedPicture.Free();
      MyPictureCache[i].ResizedPicture := nil;
    end;
  end;

  MyRoomPic.Picture.Free();
  MyKnapsackPic.Picture.Free();
end;
// ****************************************************************************
// *                   Зачистить изображение текущей комнаты                  *
// ****************************************************************************
procedure TMainForm.ResetRoomPic();
var
  i: Integer;
  w,h: Integer;
begin
  // Очищаем позиционный список графических элементы с карты игровой комнаты
  for i := 1 to ROOM_WIDTH*ROOM_HEIGHT do
  begin
    MyRoomPic.Room[i].PicIndex := -1;
  end;

  if MyRoomPic.Picture <> nil then
  begin
    MyRoomPic.Picture.Free();
    // ShowMessage('Освободили картину игровой комнаты!');
    // 05.03.2021 для версии FPC 3.2.0 фрагмент кода:
    // "if MyRoomPic.Picture <> nil then MyRoomPic.Picture.Free();"
    // при отсутствии объекта MyRoomPic.Picture (когда объект не создавался
    // вместе с формой) даст исключение, но если он был создан вместе с формой
    // (выделена память), то проверка сработает !!!
	end;

  // Расчитываем по пикселам максимально возможный размер изображения комнаты
  // и задаем растровый объект для размещения изображения
  w := GamePanel.ClientWidth div ROOM_WIDTH;
  h := GamePanel.ClientHeight div ROOM_HEIGHT;
  MyRoomPic.Picture := TBitmap.Create();
  MyRoomPic.Picture.Width := w*ROOM_WIDTH;
  MyRoomPic.Picture.Height := h*ROOM_HEIGHT;
  //Caption:=
  //  IntToStr(GamePanel.ClientWidth)+'>'+
  //  IntToStr(w)+'*'+IntToStr(ROOM_WIDTH)+'='+
  //  IntToStr(w*ROOM_WIDTH);
end;
// ****************************************************************************
// *                        Зачистить содержимое рюкзака                      *
// ****************************************************************************
procedure TMainForm.ResetKnapsackPic();
var
  i: Integer;
begin
  for i := 1 to KNAPSACK_WIDTH*KNAPSACK_HEIGHT do
  begin
    MyKnapsackPic.Knapsack[i].PicIndex := -1;
  end;
  MyKnapsackPic.Picture := TBitmap.Create();
  MyKnapsackPic.Picture.Width := PICTURE_SIZE*KNAPSACK_WIDTH;
  MyKnapsackPic.Picture.Height := PICTURE_SIZE*KNAPSACK_HEIGHT;
end;

procedure TMainForm.ResetWorld();
var
  i,j: Integer;
begin
  for i := 1 to WORLD_WIDTH*WORLD_HEIGHT do
  begin
    for j := 1 to ROOM_WIDTH*ROOM_HEIGHT do
    begin
      MyWorld[i][j].PicIndex := GetPictureCacheIndex(BACKGROUND_PIC);
    end;
  end;
end;

procedure TMainForm.ResetKnapsack();
var
  i: Integer;
begin
  for i := 1 to KNAPSACK_WIDTH*KNAPSACK_HEIGHT do
  begin
    MyKnapsack[i].PicIndex := GetPictureCacheIndex(BACKGROUND_PIC);
  end;
end;

function TMainForm.GetPlace(room: TRoomAbsNum; pos: TPlaceNum): TPlace;
var
  i: Integer;
begin
  GetPlace.PicIndex := MyWorld[room][GetAbs(pos)].PicIndex;

  // look for players
  if Length(MyWorldPlayers[room]) > 0 then
  for i := Low(MyWorldPlayers[room]) to High(MyWorldPlayers[room]) do
  begin
    if (MyWorldPlayers[room][i].Pos.X = pos.X)
    and (MyWorldPlayers[room][i].Pos.Y = pos.Y) then
    begin
      GetPlace.PicIndex := MyWorldPlayers[room][i].PicIndex;
      //WriteLn('found player to view: ' + IntToStr(GetPlace.PicIndex));
    end;
  end;
  
  // check for range errors
  if (GetPlace.PicIndex < Low(MyPictureCache))
  or (GetPlace.PicIndex > High(MyPictureCache)) then
  begin
    WriteLn('ERROR: GetPlace: range error (' +
            IntToStr(GetPlace.PicIndex) + ') of picture ' +
            'on (' + IntToStr(pos.X) + ',' + IntToStr(pos.Y) + ')');
    GetPlace.PicIndex := GetPictureCacheIndex(ERROR_PIC);
  end;
end;

function TMainForm.GetPlace(pos: TPlaceNum): TPlace;
begin
  GetPlace := GetPlace(GetAbs(MyRoomNum), pos);
end;

procedure TMainForm.SetPlace(pos: TPlaceNum; p: TPlace);
begin
  MyWorld[GetAbs(MyRoomNum)][GetAbs(pos)].PicIndex := p.PicIndex;
end;

function TMainForm.GetPlacePicName(pos: TPlaceNum): string;
begin
  GetPlacePicName := GetPictureName(GetPlace(pos).PicIndex);
end;

procedure TMainForm.SetPlacePicName(pos: TPlaceNum; pname: string);
begin
  SetPlace(pos, Place(GetPictureCacheIndex(pname)));
end;

procedure TMainForm.ResetPlace(pos: TPlaceNum);
begin
  SetPlacePicName(pos, BACKGROUND_PIC);
end;

function TMainForm.AddPlayer(room: TRoomAbsNum; pos: TPlaceNum; picindex: Integer): Integer;
var
  i: Integer;
begin
  SetLength(MyWorldPlayers[room], Length(MyWorldPlayers[room]) + 1);
  i := High(MyWorldPlayers[room]);
  //WriteLn('AddPlayer ' + IntToStr(i) + ' in ' + IntToStr(room));
  MyWorldPlayers[room][i].PicIndex := picindex;
  MyWorldPlayers[room][i].Pos := pos;
  AddPlayer := i;
end;

function TMainForm.AddPlayer(room: TRoomAbsNum; pos: TPlaceNum; picname: string): Integer;
begin
  AddPlayer := AddPlayer(room, pos, GetPictureCacheIndex(picname));
end;

procedure TMainForm.RemovePlayer(room: TRoomAbsNum; index: Integer);
begin
  MyWorldPlayers[room][index] := MyWorldPlayers[room][High(MyWorldPlayers[room])];
  SetLength(MyWorldPlayers[room], Length(MyWorldPlayers[room]) - 1);
end;

procedure TMainForm.RemovePlayer(room: TRoomAbsNum; pos: TPlaceNum);
var
  i: Integer;
begin
  for i := Low(MyWorldPlayers[room]) to High(MyWorldPlayers[room]) do
  begin
    if (MyWorldPlayers[room][i].Pos.X = pos.X)
    and (MyWorldPlayers[room][i].Pos.Y = pos.Y) then
    begin
      RemovePlayer(room, i);
      exit;
    end;
  end;
end;

function TMainForm.MovePlayer(oldroom: TRoomAbsNum; oldindex: Integer; newroom: TRoomAbsNum; newpos: TPlaceNum): Integer; // returns new index
begin
  MovePlayer := AddPlayer(newroom, newpos, MyWorldPlayers[oldroom][oldindex].PicIndex);
  RemovePlayer(oldroom, oldindex);
end;

function TMainForm.IsPlayerInRoom(picname: string): boolean;
var
  i: Integer;
  room: TRoomAbsNum;
begin
  room := GetAbs(MyRoomNum);
  for i := Low(MyWorldPlayers[room]) to High(MyWorldPlayers[room]) do
  begin
    if IsWild(GetPictureName(MyWorldPlayers[room][i].PicIndex), picname, false) then
    begin
      IsPlayerInRoom := true;
      exit;
    end;
  end;
  
  IsPlayerInRoom := false;
end;

procedure TMainForm.ResetPlayerList();
var
  room, i: Integer;
begin
  for room := 1 to WORLD_WIDTH*WORLD_HEIGHT do
    SetLength(MyWorldPlayers[room], 0);
end;

procedure TMainForm.CopyRect(DstCanvas: TCanvas; const Dest: TRect; SrcCanvas: TCanvas; const Source: TRect);

  procedure OwnCopyRect();
  var
    x,y: Integer;
    w,h: Integer;
    sw, sh: Integer;
  begin
    w := Dest.Right - Dest.Left;
    h := Dest.Bottom - Dest.Top;
    sw := Source.Right - Source.Left;
    sh := Source.Bottom - Source.Top;
    for x := 0 to w do
    for y := 0 to h do
    begin
      DstCanvas.Pixels[Dest.Left + x, Dest.Top + y] :=
        SrcCanvas.Pixels[Source.Left + (x * sw) div w,
                         Source.Top + (y * sh) div h];
    end;
  end;

begin
{$IFDEF win32}
  // WIN API StretchBlt is shit !
  OwnCopyRect();
{$ELSE}
  // on something else, we have already a good copyrect ...
  DstCanvas.CopyRect(Dest, SrcCanvas, Source);
{$ENDIF win32}
end;

procedure TMainForm.DrawRoom();
var
  i: Integer;
  pic: TBitmap;
  w,h: Integer;
  ps: string;
  x,y: Integer;
begin

  nEntry:=nEntry+1;
  //Caption:='Вход='+IntToStr(nEntry);

  w := GamePanel.ClientWidth div ROOM_WIDTH;
  h := GamePanel.ClientHeight div ROOM_HEIGHT;

  // TODO: check range errors
  for i := 1 to ROOM_WIDTH*ROOM_HEIGHT do
  begin
    // only make updates
    if GetPlace(GetNumP(i)).PicIndex <> MyRoomPic.Room[i].PicIndex then
    begin
      pic := MyPictureCache[GetPlace(GetNumP(i)).PicIndex].ResizedPicture;
      if pic = nil then
      begin // we have to create a new resized cache picture
        pic := TBitmap.Create();
        pic.Width := w;
        pic.Height := h;
        CopyRect(
                 pic.Canvas,
                 Rect(0,0,w,h),
                 MyPictureCache[GetPlace(GetNumP(i)).PicIndex].Picture.Canvas,
                 Rect(0,0,PICTURE_SIZE,PICTURE_SIZE)
                 );
        MyPictureCache[GetPlace(GetNumP(i)).PicIndex].ResizedPicture := pic;
      end;
      
      MyRoomPic.Picture.Canvas.Draw(
                                    (GetNumP(i).X-1)*w,
                                    (GetNumP(i).Y-1)*h,
                                    pic
                                    );
      MyRoomPic.Room[i] := GetPlace(GetNumP(i));
      //WriteLn('DrawRoom: update: ' +
      //        '(' + IntToStr(GetNumP(i).X) + ',' +
      //              IntToStr(GetNumP(i).Y) + ')' +
      //         ' to: ' + IntToStr(MyRoomPic.Room[i]));
    end;
  end;

  // draw the hole area to screen (to the GamePanel)
  GamePanel.Canvas.Draw(0,0,MyRoomPic.Picture);

  // draw pause-state
  if (not MyEditorMode) and (MyPauseState = true) then
  begin
    ps := 'Pause';
    GamePanel.Canvas.Font := MainForm.Font;
    x := (GamePanel.ClientWidth - GamePanel.Canvas.TextWidth(ps)) div 2;
    y := (GamePanel.ClientHeight - GamePanel.Canvas.TextHeight(ps)) div 2;
    GamePanel.Canvas.TextOut(x,y,ps);
  end;

  // draw focus
  // TODO
end;

procedure TMainForm.DrawKnapsack();
var
  i: Integer;
  pic: TBitmap;
  x,y,w,h: Integer;
begin
  // TODO: better with pointers, but the code should be readable by beginners
  if MyEditorMode then
  begin
    for i := 1 to KNAPSACK_WIDTH*KNAPSACK_HEIGHT do
    begin
      // only make updates
      if MyEditorKnapsack[i].PicIndex <> MyKnapsackPic.Knapsack[i].PicIndex then
      begin
        if (MyEditorKnapsack[i].PicIndex >= 0) and (MyEditorKnapsack[i].PicIndex <= High(MyPictureCache)) then
        begin
          pic := MyPictureCache[MyEditorKnapsack[i].PicIndex].Picture;
          MyKnapsackPic.Picture.Canvas.Draw(
                                            ((i-1) mod KNAPSACK_WIDTH)*PICTURE_SIZE,
                                            ((i-1) div KNAPSACK_WIDTH)*PICTURE_SIZE,
                                            pic
                                            );
          MyKnapsackPic.Knapsack[i] := MyEditorKnapsack[i];
        end
        else // range error
        begin
          WriteLn('ERROR: DrawKnapsack: range error of ' +
                  IntToStr(i) + ': ' + IntToStr(MyEditorKnapsack[i].PicIndex));
        end;
      end;
    end;
  end
  else // in game mode (not MyEditorMode)
  begin
    for i := 1 to KNAPSACK_WIDTH*KNAPSACK_HEIGHT do
    begin
      // only make updates
      if MyKnapsack[i].PicIndex <> MyKnapsackPic.Knapsack[i].PicIndex then
      begin
        if (MyKnapsack[i].PicIndex >= 0) and (MyKnapsack[i].PicIndex <= High(MyPictureCache)) then
        begin
          pic := MyPictureCache[MyKnapsack[i].PicIndex].Picture;
          MyKnapsackPic.Picture.Canvas.Draw(
                                            ((i-1) mod KNAPSACK_WIDTH)*PICTURE_SIZE,
                                            ((i-1) div KNAPSACK_WIDTH)*PICTURE_SIZE,
                                            pic
                                            );
          MyKnapsackPic.Knapsack[i] := MyKnapsack[i];
          //WriteLn('DrawKnapsack: update: ' +
          //        '(' + IntToStr(i) + ')' +
          //         ' to: ' + IntToStr(MyKnapsackPic.Knapsack[i]));
        end
        else // range error
        begin
          WriteLn('ERROR: DrawKnapsack: range error of ' +
                  IntToStr(i) + ': ' + IntToStr(MyKnapsack[i].PicIndex));
        end;
      end;
    end;
  end;
  
  // draw the hole area to screen (to the KnapsackPanel)
  w := KnapsackPanel.ClientWidth div KNAPSACK_WIDTH;
  h := KnapsackPanel.ClientHeight div KNAPSACK_HEIGHT;
  CopyRect(
           KnapsackPanel.Canvas,
           Rect(0,0,w*KNAPSACK_WIDTH,h*KNAPSACK_HEIGHT),
           MyKnapsackPic.Picture.Canvas,
           Rect(0,0,MyKnapsackPic.Picture.Width,MyKnapsackPic.Picture.Height)
           );
                                
  // draw selection
  x := (MyKnapsackSelection-1) mod KNAPSACK_WIDTH;
  y := (MyKnapsackSelection-1) div KNAPSACK_WIDTH;
  //KnapsackPanel.Canvas.Color := clBlack;
  KnapsackPanel.Canvas.Line(x*w,y*h,x*w,(y+1)*h-1);
  KnapsackPanel.Canvas.Line(x*w,y*h,(x+1)*w-1,y*h);
  KnapsackPanel.Canvas.Line((x+1)*w-1,y*h,(x+1)*w-1,(y+1)*h-1);
  KnapsackPanel.Canvas.Line(x*w,(y+1)*h-1,(x+1)*w-1,(y+1)*h-1);
  
  // draw focus
  // TODO
end;

procedure TMainForm.DrawInfo();
var
  s1,s2,s3: string;
begin
  s1 := 'Leben: ' + IntToStr(MyLife);
  s2 := 'Punkte: ' + IntToStr(MyScores);
  s3 := 'Diamanten: ' + IntToStr(Length(MyDiamonds));

  if s1 <> LifeLabel.Caption then LifeLabel.Caption := s1;
  if s2 <> ScoresLabel.Caption then ScoresLabel.Caption := s2;
  if s3 <> DiamondsLabel.Caption then DiamondsLabel.Caption := s3;
end;

procedure TMainForm.ShowMsg(msg: string);

  procedure SetEffectState(c: Integer);
  begin
    // TODO: how to use rgb-colors?
    if c > 255 then c := 255;
    MessageBar.Color := TColor(c + 256*c + 256*256*c);
    //FPColorToTColor(FPColor(c,c,c));
    MessageBar.Font.Color := TColor((1-c) + 256*(1-c) + 256*256*(1-c));
    //FPColorToTColor(FPColor(255-c,255-c,255-c));
  end;
  
var
  c: Integer;
begin
  MessageBar.Caption := msg;

  {c := 0;
  repeat
    c := c + 10;
    SetEffectState(c);
    Delay(10);
  until c >= 255;}
  
  //MessageBar.Color := clBlack;
  //Delay(50);
  //MessageBar.Color := clWhite;
end;

procedure TMainForm.SetPauseState(s: boolean);
begin
  if (s <> MyPauseState) then
  begin
    MyPauseState := s;
    mnuOptionsPause.Checked := s;
    DrawRoom();
  end;
end;

procedure TMainForm.ShowMsg(msgs: array of string);
begin
  ShowMsg(RandomFrom(msgs));
end;
                           
function TMainForm.GetPictureName(index: Integer): string; // returns filename
begin
  // check for range errors
  if (index < Low(MyPictureCache)) or (index > High(MyPictureCache)) then
  begin
    WriteLn('ERROR: GetPictureName: range error (' +
            IntToStr(index) + ') of picture');
    index := GetPictureCacheIndex(ERROR_PIC);
  end;

  GetPictureName := MyPictureCache[index].FileName;
end;
// ****************************************************************************
// *  По спецификации файла определить индекс элемента в массиве загруженных  *
// *      графических элементов игры (при отсутствии элемента, попытаться     *
// *              загрузить его и присвоить новый индекс)                     *
// ****************************************************************************
function TMainForm.GetPictureCacheIndex(fname: string): Integer;
var
  i: Integer;
  tmp, tmp2: TBitmap;
begin
  // Если файл не указан, то считаем, что это фоновый эемент
  if fname = '' then fname := BACKGROUND_PIC;
  // Ищем элемент в массиве, возвращаем его номер и завершаем функцию
  for i := Low(MyPictureCache) to High(MyPictureCache) do
  begin
    if(MyPictureCache[i].FileName = fname) then // found it!
    begin
      GetPictureCacheIndex := i;
      exit;
    end;
  end;
  // Если элемента в масиве еще нет, то попытаемся загрузить его из файла
  tmp := TBitmap.Create();
  tmp.TransparentColor := TColor(1); // it's a hack (needed for mac os x version); i hope, i never used this color
  tmp.Transparent := false; // this doesn't seems to work very well
  try
    tmp.LoadFromFile(fname);
  except
    on error: Exception do
    begin
      WriteLn('ERROR: GetPictureCacheIndex: could not load ' +
              fname + ': ' + error.Message);
      GetPictureCacheIndex := 0;
      if (fname <> ERROR_PIC) then
      begin
        GetPictureCacheIndex := GetPictureCacheIndex(ERROR_PIC);
      end;
      tmp.Free();
      exit;
    end;
  end;
  
  // resize it
  tmp2 := TBitmap.Create();
  tmp2.Width := PICTURE_SIZE;
  tmp2.Height := PICTURE_SIZE;
  CopyRect(
           tmp2.Canvas,
           Rect(0,0,PICTURE_SIZE,PICTURE_SIZE),
           tmp.Canvas,
           Rect(0,0,tmp.Width,tmp.Height)
           );
  tmp.Free(); // we don't need it anymore

  // put it in the cache
  SetLength(MyPictureCache, Length(MyPictureCache) + 1);
  i := High(MyPictureCache);
  MyPictureCache[i].FileName := fname;
  MyPictureCache[i].Picture := tmp2;
  MyPictureCache[i].ResizedPicture := nil;
  GetPictureCacheIndex := i;
end;

function TMainForm.GetPicture(index: Integer): TBitmap;
begin
  // check for range errors
  if (index < Low(MyPictureCache)) or (index > High(MyPictureCache)) then
  begin
    WriteLn('ERROR: GetPicture: range error (' +
            IntToStr(index) + ') of picture');
    index := GetPictureCacheIndex(ERROR_PIC);
  end;

  GetPicture := MyPictureCache[index].Picture;
end;

function TMainForm.GetPicture(fname: string): TBitmap;
var
  i: Integer;
  tmp: TBitmap;
begin
  // look in my cache, if the file is there
  i := GetPictureCacheIndex(fname);
  if i >= 0 then
  begin
    GetPicture := MyPictureCache[i].Picture;
    exit;
  end;

  // TODO: we have a problem
  WriteLn('ERROR: GetPicture: cannot load ' + fname);
end;

procedure TMainForm.ResetPictureResizedCache();
var
  i: Integer;
begin
  for i := Low(MyPictureCache) to High(MyPictureCache) do
  begin
    if MyPictureCache[i].ResizedPicture <> nil then
    begin
      MyPictureCache[i].ResizedPicture.Free();
      MyPictureCache[i].ResizedPicture := nil;
    end;
  end;
end;

function TMainForm.IsPosInsideRoom(x,y: Integer): boolean;
begin
  Result := ((x >= 2) and (x <= ROOM_WIDTH-1) and (y >= 2) and (y <= ROOM_HEIGHT-1));
end;

function TMainForm.AddToKnapsack(picindex: Integer): boolean;
var
  i: Integer;
begin
  // don't use KNAPSACK_WIDTH*KNAPSACK_HEIGHT here for compatibility with Robot1
  for i := 1 to KNAPSACK_MAX do
  begin
    if GetPictureName(MyKnapsack[i].PicIndex) = BACKGROUND_PIC then // empty place
    begin
      MyKnapsack[i].PicIndex := picindex;
      AddToKnapsack := true;
      DrawKnapsack();
      exit;
    end;
  end;
  
  AddToKnapsack := false;
end;

function TMainForm.AddToKnapsack(picname: string): boolean;
begin
  AddToKnapsack := AddToKnapsack(GetPictureCacheIndex(picname));
end;

function TMainForm.IsInKnapsack(picname: string): boolean;
var
  i: Integer;
begin
  // search in hole knapsack
  for i := 1 to KNAPSACK_WIDTH*KNAPSACK_HEIGHT do
  begin
    if GetPictureName(MyKnapsack[i].PicIndex) = picname then
    begin
      IsInKnapsack := true;
      exit;
    end;
  end;
  
  IsInKnapsack := false;
end;

procedure TMainForm.ChangeKnapsackSelection(dir: TMoveDirection);
var
  x,y: Integer;
begin
  x := ((MyKnapsackSelection-1) mod KNAPSACK_WIDTH) + 1;
  y := ((MyKnapsackSelection-1) div KNAPSACK_WIDTH) + 1;
  case dir of
  mdLeft:
  begin
    if x = 1 then exit;
    x := x - 1;
  end;
  mdRight:
  begin
    if x = KNAPSACK_WIDTH then exit;
    x := x + 1;
  end;
  mdUp:
  begin
    if y = 1 then exit;
    y := y - 1;
  end;
  mdDown:
  begin
    if y = KNAPSACK_HEIGHT then exit;
    y := y + 1;
  end;
  end;
  MyKnapsackSelection := (y-1)*KNAPSACK_WIDTH + x;

  DrawKnapsack();
end;

procedure TMainForm.AddScores(num: Integer);
begin
  MyScores := MyScores + num;
  DrawInfo();
end;

procedure TMainForm.AddLife();
begin
  MyLife := MyLife + 1; // TODO: only 10 lifes?
  DrawInfo();
end;

function TMainForm.RemoveLife(): boolean;
begin
  // TODO: give additional info
  if MyLife = 0 then
  begin // death
    ShowMsg([
             'Ich bin tot.',
             'Der Sensemann kommt.',
             'Das letzte Leben verabschiedet sich.'
             ]);
    ShowMessage(
                'Ich bin sicher, in anderen Welten wдre jetzt wirklich Ende, ' +
                'geschweige dessen, dass du ьberhaupt mehrere Leben hast!'
                );
    RemoveLife := false;
  end
  else
  begin
    MyLife := MyLife - 1;
    DrawInfo();
    RemoveLife := true;
  end;
end;

procedure TMainForm.SetFocus(f: TFocus);
begin
  if MyFocus <> f then
  begin
    MyFocus := f;
    DrawRoom();
    DrawKnapsack();
  end;
end;

procedure TMainForm.ChangeFocus();
begin
  if MyFocus = fcRoom then SetFocus(fcKnapsack) else SetFocus(fcRoom);
end;

procedure TMainForm.PlaySound(fname: string);
begin
  if not MySoundState then exit;

  if not FileExists(fname) then
  begin
    WriteLn('ERROR: PlaySound: ' + fname + ' not found');
    exit;
  end;
  
{$IFDEF win32}
  // TODO: cache sounds
  sndPlaySound(PChar(fname), SND_NODEFAULT Or SND_ASYNC);
{$ELSE}
  // TODO: play the file
{$ENDIF}
end;

procedure TMainForm.LoadWorld(fname: string);
var
  f: TextFile;
  tmp: string;
  roomnum: TRoomAbsNum;
  placenum: TPlaceAbsNum;
  i: Integer;
begin
  { file content:
  :RAUM1
  bild1.bmp
  bild2.bmp
    ...
  :RAUM2
    ...
  :RAUM20
    ...
  }

  AssignFile(f, fname); // open file
  try
    Reset(f); // go to the beginning

    ResetPlayerList();

    while not EOF(f) do
    begin
      ReadLn(f, tmp);
      tmp := Trim(tmp);
      if tmp <> '' then
      begin
        if AnsiStartsStr(':RAUM', UpperCase(tmp)) then // new room
        begin
          roomnum := StrToInt(AnsiRightStr(tmp, Length(tmp) - 5));
          placenum := 1;
        end
        else
        begin // next place
          MyWorld[roomnum][placenum].PicIndex := GetPictureCacheIndex(tmp);

          // look for players
          for i := Low(PLAYER_PICS) to High(PLAYER_PICS) do
          begin
            if IsWild(tmp, PLAYER_PICS[i], true) then
            begin // it's a player
              AddPlayer(roomnum, GetNumP(placenum), tmp);
              MyWorld[roomnum][placenum].PicIndex := GetPictureCacheIndex(BACKGROUND_PIC);
            end;
          end;

          if placenum < ROOM_WIDTH*ROOM_HEIGHT then placenum := placenum + 1;
        end;
      end;
    end;

  finally
    CloseFile(f);
  end;
end;

procedure TMainForm.SaveWorld(fname: string);
var
  f: TextFile;
  i: Integer;
  roomnum, placenum: Integer;
  placeunder: string;
  tmp: string;
begin
  // see also: LoadWorld

  AssignFile(f, fname); // open file
  try
    Rewrite(f); // start writing

    for roomnum := 1 to WORLD_WIDTH*WORLD_HEIGHT do
    begin
      WriteLn(f, ':RAUM' + IntToStr(roomnum));
      for placenum := 1 to ROOM_WIDTH*ROOM_HEIGHT do
        WriteLn(f, GetPictureName(GetPlace(roomnum, GetNumP(placenum)).PicIndex));
    end;

  finally
    CloseFile(f);
  end;
end;

procedure TMainForm.LoadGame(fname: string);
var
  f: TextFile;
  tmp: string;
  roomnum: TRoomAbsNum;
  placenum: TPlaceAbsNum;
  i: Integer;
  roomnr: TRoomAbsNum;
  placeunder: string;
begin
  { file content:
  [Room-Nr]
  [Name]
  [Scores]
  [Life]
  [Diamond status 1]
  [Diamond status 2]
  [Diamond status 3]
  [Place under player]
  :RUCK
  bild1.bmp
  ...
  :RAUM1
  bild1.bmp
  bild2.bmp
    ...
  :RAUM2
    ...
  :RAUM20
    ...
  }

  AssignFile(f, fname); // open file
  try
    Reset(f); // go to the beginning

    // roomnr
    if not EOF(f) then
    begin
      ReadLn(f, tmp);
      tmp := Trim(tmp);
      roomnr := StrToInt(tmp);
    end;
    
    // name
    if not EOF(f) then
    begin
      ReadLn(f, tmp);
      tmp := Trim(tmp);
      // TODO: handle name in some way
    end;
    
    // scores
    if not EOF(f) then
    begin
      ReadLn(f, tmp);
      tmp := Trim(tmp);
      MyScores := StrToInt(tmp);
    end;

    // life
    if not EOF(f) then
    begin
      ReadLn(f, tmp);
      tmp := Trim(tmp);
      MyLife := Abs(StrToInt(tmp));
    end;
    
    // diamond states
    SetLength(MyDiamonds, 0);
    for i := 1 to 3 do
    if not EOF(f) then
    begin
      ReadLn(f, tmp);
      tmp := UpperCase(Trim(tmp));
      if (tmp = 'WAHR')
      or (tmp = '1')
      or (tmp = 'TRUE')
      or (tmp = '-1')
      or (tmp = 'JA')
      or (tmp = 'YES') then
      begin
        SetLength(MyDiamonds, Length(MyDiamonds) + 1);
        MyDiamonds[High(MyDiamonds)].DiamondNr := i;
      end;
    end;

    // place under player
    if not EOF(f) then
    begin
      ReadLn(f, tmp);
      tmp := Trim(tmp);
      placeunder := LowerCase(tmp);
    end;
    
    // has to be: ':RUCK' (check not needed)
    if not EOF(f) then
      ReadLn(f, tmp);
      
    // knapsack
    // don't use KNAPSACK_WIDTH*KNAPSACK_HEIGHT here for compatibility with Robot1
    // TODO: dynamically loading till beginning of rooms (":RAUM*")
    for i := 1 to KNAPSACK_MAX do
    begin
      ReadLn(f, tmp);
      tmp := LowerCase(Trim(tmp));
      MyKnapsack[i].PicIndex := GetPictureCacheIndex(tmp);
    end;

    // world (rooms)
    ResetPlayerList();
    while not EOF(f) do
    begin
      ReadLn(f, tmp);
      tmp := Trim(tmp);
      if (tmp <> '') and (UpperCase(tmp) <> 'ENDE') then
      begin
        if AnsiStartsStr(':RAUM', UpperCase(tmp)) then // new room
        begin
          roomnum := StrToInt(AnsiRightStr(tmp, Length(tmp) - 5));
          placenum := 1;
        end
        else
        begin // next place
          tmp := LowerCase(tmp);
          //WriteLn('LoadWorld: ' + IntToStr(roomnum) + ',' +
          //        IntToStr(placenum) + ' ' + tmp);
          MyWorld[roomnum][placenum].PicIndex := GetPictureCacheIndex(tmp);

          // look for players
          for i := Low(PLAYER_PICS) to High(PLAYER_PICS) do
          begin
            if IsWild(tmp, PLAYER_PICS[i], true) then
            begin // it's a player
              AddPlayer(roomnum, GetNumP(placenum), tmp);
              if tmp = 'figur.bmp' then
                MyWorld[roomnum][placenum].PicIndex := GetPictureCacheIndex(placeunder)
              else
                MyWorld[roomnum][placenum].PicIndex := GetPictureCacheIndex(BACKGROUND_PIC);
            end;
          end;

          if placenum < ROOM_WIDTH*ROOM_HEIGHT then placenum := placenum + 1;
        end;
      end;
    end;

  finally
    CloseFile(f);
  end;
  
  MoveToRoom(GetNumR(roomnr));
  DrawInfo();
  DrawKnapsack();
  DrawRoom();
  SetPauseState(true);
end;

procedure TMainForm.SaveGame(fname: string);
var
  f: TextFile;
  i: Integer;
  diamonds: array[1..3] of boolean;
  roomnum, placenum: Integer;
  placeunder: string;
  tmp: string;
begin
  AssignFile(f, fname); // open file
  try
    Rewrite(f); // start writing

    WriteLn(f, IntToStr(GetAbs(MyRoomNum)));
    WriteLn(f, 'Albert'); // TODO: name handling
    WriteLn(f, IntToStr(MyScores));
    WriteLn(f, IntToStr(MyLife));

    // get diamond states
    for i := 1 to 3 do
      diamonds[i] := false;
    for i := Low(MyDiamonds) to High(MyDiamonds) do
      if (MyDiamonds[i].DiamondNr >= 1)
      and (MyDiamonds[i].DiamondNr <= 3) then
      begin
        diamonds[MyDiamonds[i].DiamondNr] := true;
      end;

    for i := 1 to 3 do
      if diamonds[i] then
        WriteLn(f, '1')
      else
        WriteLn(f, '0');

    // get place under mainplayer
    placeunder := '';
    for roomnum := 1 to WORLD_WIDTH*WORLD_HEIGHT do
    for i := Low(MyWorldPlayers[roomnum]) to High(MyWorldPlayers[roomnum]) do
      if GetPictureName(MyWorldPlayers[roomnum][i].PicIndex) = 'figur.bmp' then
        placeunder := GetPictureName(MyWorld[roomnum][GetAbs(MyWorldPlayers[roomnum][i].Pos)].PicIndex);
    if placeunder = BACKGROUND_PIC then
      placeunder := '';
    
    WriteLn(f, placeunder);

    WriteLn(f, ':RUCK');
    // don't use KNAPSACK_WIDTH*KNAPSACK_HEIGHT here for compatibility with Robot1
    for i := 1 to KNAPSACK_MAX do
    begin
      tmp := GetPictureName(MyKnapsack[i].PicIndex);
      if tmp = BACKGROUND_PIC then
        tmp := '';
      WriteLn(f, tmp);
    end;
    WriteLn(f, 'ENDE');
    
    for roomnum := 1 to WORLD_WIDTH*WORLD_HEIGHT do
    begin
      WriteLn(f, ':RAUM' + IntToStr(roomnum));
      for placenum := 1 to ROOM_WIDTH*ROOM_HEIGHT do
        WriteLn(f, GetPictureName(GetPlace(roomnum, GetNumP(placenum)).PicIndex));
    end;
    
  finally
    CloseFile(f);
  end;
end;

function TMainForm.ShowLoadGameDialog(): boolean;
begin
  ShowLoadGameDialog := false;
  if OpenGameDialog.Execute() then
  if FileExists(OpenGameDialog.FileName) then
  begin
    LoadGame(OpenGameDialog.FileName);
    ShowLoadGameDialog := true;
  end;
end;

function TMainForm.ShowSaveGameDialog(): boolean;
begin
  ShowSaveGameDialog := false;
  if SaveGameDialog.Execute() then
  begin
    SaveGame(SaveGameDialog.FileName);
    ShowSaveGameDialog := true;
  end;
end;

initialization
  {$I umainform.lrs}

end.

