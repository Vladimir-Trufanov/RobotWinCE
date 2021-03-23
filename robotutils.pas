// LAZARUS, WIN10                                        *** RobotUtils.pas ***

// ****************************************************************************
// *      Библиотека прикладных процедур для игровой программы Robot, v1.8    *
// ****************************************************************************

//                                                   Автор:       Труфанов В.Е.
//                                                   Дата создания:  09.03.2021
// Copyright © 2021 TVE                              Посл.изменение: 10.03.2021

unit RobotUtils;

{$mode objfpc}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, GraphType, Crt, StrUtils, StdCtrls, ComCtrls, Menus, LCLType
{$IFDEF win32}
  ,MMSystem
{$ENDIF}
  ;
  {
  LResources,
  Buttons, GraphType, Crt, StrUtils, ComCtrls, Menus, LCLType,

  Classes,Controls,SysUtils,Graphics,Dialogs,Forms,ExtCtrls,
  {$IFDEF win32}
    MMSystem,
  {$ENDIF}
  StdCtrls;
  }
// Вывести сообщение об ошибке красным жирным текстом на TLabel
procedure CaptiError(cMessage:String; obj:TLabel; Mode:integer=1);
// Озвучить событие заданным файлом
procedure PlaySound(fname:string; MySoundState:boolean=false);
// Пропорционально размерам перенести изображение исходного прямоугольника
// на целевой прямоугольник
procedure SmudgeRect(
  DstCanvas:TCanvas; const Dest:TRect;
  SrcCanvas:TCanvas; const Source:TRect);

implementation

// ****************************************************************************
// *      Вывести сообщение об ошибке красным жирным текстом на TLabel        *
// ****************************************************************************
procedure CaptiError(cMessage:String; obj:TLabel; Mode:integer=1);
var
  oFont:TFont;
begin
  oFont:=obj.Font;
  obj.Font.Color:=clRed;
  obj.Font.Style:=[fsBold];
  if (Mode=1) then obj.Caption:='ERROR: '+cMessage
  else obj.Caption:=cMessage;
end;
// ****************************************************************************
// *                        Озвучить событие заданным файлом                  *
// ****************************************************************************
procedure PlaySound(fname:string; MySoundState:boolean=false);
var
  myCharPtr: PChar;
  iPChar: Integer;
begin
  // Если звук отключен, то выходим из процедуры
  if not MySoundState then exit;
  // Если звуковой файл не найден, то выдаем ошибку и выходим из процедуры
  if not FileExists(fname) then
  begin
    WriteLn('ERROR: PlaySound: ' + fname + ' not found');
    exit;
  end;
  {$IFDEF win32}
    // Для использования функции воспроизведения звукового файла
    // делаем преобразование string -> PChar через указатель
    // на первый символ в строке
    iPChar:=1;
    myCharPtr:=addr(fname[iPChar]);
    sndPlaySound(myCharPtr, SND_NODEFAULT or SND_ASYNC);
  {$ELSE}
    // TODO: play the file
  {$ENDIF}
end;
// ****************************************************************************
// *  Пропорционально размерам перенести изображение исходного прямоугольника *
// *                                    на целевой                            *
// ****************************************************************************
{
procedure TMainForm.Button1Click(Sender: TObject);
var
  r1, r2: TRect; // координаты углов прямоугольников
begin
  // зададим координаты углом прямоугольников
  r2 := Rect(30,24,35,29);
  r1 := Rect(20,50,80,90);
  with KnapsackPanel.Canvas do
    begin
      Brush.Color:= clRed;
      FillRect(r1); // закрашенный прямоугольник
      Brush.Color:= clGreen;
      FillRect(r2); // закрашенный прямоугольник
    end;
  //
  SmudgeRect(KnapsackPanel.Canvas,r1,KnapsackPanel.Canvas,r2);
end;
}
procedure SmudgeRect(
  DstCanvas:TCanvas; const Dest:TRect;
  SrcCanvas:TCanvas; const Source:TRect);
var
  x0,y0,x1,y1: Integer;
  w,h: Integer;
  sw, sh: Integer;
begin
  w := Dest.Right - Dest.Left;
  h := Dest.Bottom - Dest.Top;
  sw := Source.Right - Source.Left;
  sh := Source.Bottom - Source.Top;
  for x0 := 0 to w do
  for y0 := 0 to h do
  begin
    x1:=(x0*sw) div w;
    y1:=(y0*sh) div h;
    DstCanvas.Pixels[Dest.Left   + x0, Dest.Top   + y0]:=
    SrcCanvas.Pixels[Source.Left + x1, Source.Top + y1];
  end;
end;

end.

// ********************************************************* RobotUtils.pas ***

