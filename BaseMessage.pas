unit BaseMessage;

interface

uses System.UITypes, System.Generics.Collections, FMX.Graphics;

type
  TRGBCollection = record
    R, G, B: Int64;
  end;

  TRGB = packed record
    B, G, R: Byte;
  end;

  PRGB = ^TRGB;

  TFontData = array of array of TAlphaColor;

  TFontClass = class
  private
    FWidth: integer;
    FStart: Single;
    FData: TFontData;
  public
    constructor Create(data: TFontData); overload; virtual;
    property Start: Single read FStart write FStart;
    property Width: integer read FWidth;
    property data: TFontData read FData;
  end;

const
  th = 200;
  wsize: integer = 32;
  hsize: integer = 32;

var
  Chars: array [Char] of TFontData;
  List: TObjectList<TFontClass>;

implementation

uses System.Math;

{ TFontClass }

constructor TFontClass.Create(data: TFontData);
var
  num: integer;
  obj: TFontClass;
  rec: TAlphaColorRec;
begin
  FData := data;
  num := 0;
  for var i := 0 to wsize - 1 do
    for var j := 0 to hsize - 1 do
    begin
      rec := TAlphaColorRec.Create(data[i, j]);
      if (num < i) and ((rec.R + rec.B + rec.G) div 3 > th) then
        num := i;
    end;
  FWidth := Ifthen(num = 0, wsize div 2, num);
  if List.Count > 0 then
  begin
    obj := List.Last;
    FStart := obj.Start + obj.Width + 1;
  end
  else
    FStart := wsize;
end;

initialization

List := TObjectList<TFontClass>.Create;

finalization

List.Free;

end.
