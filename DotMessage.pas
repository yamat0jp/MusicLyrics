unit DotMessage;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, Winapi.Windows, Vcl.ExtCtrls,
  Vcl.Graphics, System.Types, System.Generics.Collections;

type
  TFontData = array of array of TColor;

  TFontClass = class
  private
    FWidth: integer;
    FStart: integer;
    FData: TFontData;
  public
    constructor Create(data: TFontData); overload; virtual;
    property Start: integer read FStart write FStart;
    property Width: integer read FWidth;
    property data: TFontData read FData;
  end;

  TDotMessage = class(TPaintBox)
  private
    FLines: TStrings;
    FTimer: TTimer;
    FSize: integer;
    FLoop: Boolean;
    procedure filter(bmp: TBitmap; out data: TFontData);
    { Private êÈåæ }
  protected
    procedure Paint; override;
    procedure Resize; override;
    function GetEnabled: Boolean; override;
    procedure SetEnabled(Value: Boolean); override;
    { Protected êÈåæ }
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Execute;
    procedure TimerOnTime(Sender: TObject); dynamic;
    { Public êÈåæ }
  published
    property Lines: TStrings read FLines write FLines;
    property Loop: Boolean read FLoop write FLoop stored true default true;
    { Published êÈåæ }
  end;

implementation

type
  TRGBCollection = record
    R, G, B: Int64;
  end;

  TRGB = packed record
    B, G, R: Byte;
  end;

  PRGB = ^TRGB;

const
  th = 150;
  wsize: integer = 32;
  hsize: integer = 32;

var
  Chars: array [Char] of TFontData;
  List: TObjectList<TFontClass>;

constructor TDotMessage.Create(AOwner: TComponent);
begin
  inherited;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 120;
  FTimer.Enabled := false;
  FTimer.OnTimer := TimerOnTime;
  FLoop := true;
end;

destructor TDotMessage.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TDotMessage.Execute;
var
  bmp: TBitmap;
  data: TFontData;
begin
  bmp := TBitmap.Create(Height, Height);
  try
    with bmp.Canvas do
    begin
      Font.Height := Height;
      Font.Style := [TFontStyle.fsBold];
      for var ch in FLines.Text do
      begin
        if Chars[ch] <> nil then
          data := Chars[ch]
        else
        begin
          Brush.Color := TColors.Gray;
          FillRect(TRect.Create(0, 0, Height, Height));
          Font.Color := TColors.White;
          bmp.Canvas.TextOut(0, 0, ch);
          filter(bmp, data);
          Chars[ch] := Copy(data, 0, Length(data));
        end;
        List.Add(TFontClass.Create(data));
      end;
    end;
  finally
    bmp.Free;
  end;
  Paint;
  FTimer.Enabled := true;
end;

procedure TDotMessage.filter(bmp: TBitmap; out data: TFontData);
var
  p: PRGB;
  Color: TRGB;
  bx, by: integer;
  R, G, B, tmp, num: Int64;
  sum: array of array of TRGBCollection;
  cnt: array of array of integer;
begin
  SetLength(sum, wsize, hsize);
  SetLength(cnt, wsize, hsize);
  SetLength(data, wsize, hsize);
  bmp.PixelFormat := pf24BIt;
  for var y := 0 to bmp.Height - 1 do
  begin
    p := bmp.Scanline[y];

    for var x := 0 to bmp.Width - 1 do
    begin

      // Ç«ÇÃÉuÉçÉbÉNÇ©
      bx := x div FSize; // 0..7
      by := y div FSize; // 0..15

      // îÕàÕäOñhé~Åií[ÇÃä€ÇﬂåÎç∑ëŒçÙÅj
      if bx > wsize - 1 then
        bx := wsize - 1;
      if by > hsize - 1 then
        by := hsize - 1;

      // ì¡í•ó ÇÃí~êœ
      sum[bx, by].R := sum[bx, by].R + p^.R;
      sum[bx, by].G := sum[bx, by].G + p^.G;
      sum[bx, by].B := sum[bx, by].B + p^.B;
      cnt[bx, by] := cnt[bx, by] + 1;

      Inc(p);
    end;
  end;

  // ïΩãœílÇ data Ç…äiî[
  for bx := 0 to wsize - 1 do
    for by := 0 to hsize - 1 do
    begin
      if cnt[bx, by] = 0 then
      begin
        data[bx, by] := RGB(100, 100, 100);
        continue;
      end;
      num := cnt[bx, by];
      tmp := sum[bx, by].R div num;
      if tmp > th then
        R := 255
      else
        R := 100;
      tmp := sum[bx, by].G div num;
      if tmp > th then
        G := 255
      else
        G := 100;
      tmp := sum[bx, by].B div num;
      if tmp > th then
        B := 255
      else
        B := 100;
      Color.R := R;
      Color.G := G;
      Color.B := B;
      data[bx, by] := RGB(R, G, B);
    end;
end;

function TDotMessage.GetEnabled: Boolean;
begin
  inherited;
  result := FTimer.Enabled;
end;

procedure TDotMessage.Paint;
var
  st: integer;
  obj: TFontClass;
begin
  inherited;
  FSize := Height div hsize;
  Canvas.Brush.Color := clGray;
  Canvas.FillRect(TRect.Create(0, 0, Width, Height));
  Canvas.Brush.Color := clWhite;
  for var k := List.Count - 1 downto 0 do
  begin
    obj := List[k];
    if obj.Start > (Width div FSize) then
      continue;
    for var i := 0 to wsize - 1 do
      for var j := 0 to hsize - 1 do
      begin
        st := obj.Start;
        if obj.data[i, j] <> clWhite then
          continue;
        Canvas.Ellipse(TRect.Create((i + st) * FSize, j * FSize,
          (i + st + 1) * FSize, (j + 1) * FSize));
      end;
  end;
end;

procedure TDotMessage.Resize;
begin
  inherited;
  FSize := Height div hsize;
end;

procedure TDotMessage.SetEnabled(Value: Boolean);
begin
  inherited;
  FTimer.Enabled := Value;
end;

procedure TDotMessage.TimerOnTime(Sender: TObject);
var
  obj: TFontClass;
begin
  for var i := List.Count - 1 downto 0 do
  begin
    obj := List[i];
    obj.Start := obj.Start - 2;
    if obj.Start + obj.Width < 0 then
      List.Delete(i);
  end;
  if FLoop and (List.Count < Length(FLines.Text)) then
    Execute;
  Paint;
end;

{ TFontClass }

constructor TFontClass.Create(data: TFontData);
var
  num: integer;
  obj: TFontClass;
begin
  FData := data;
  num := 0;
  for var i := 0 to wsize - 1 do
    for var j := 0 to hsize - 1 do
      if (data[i, j] = clWhite) and (num < i) then
        num := i;
  if List.Count > 0 then
  begin
    obj := List.Last;
    FStart := obj.Start + obj.Width + 1;
  end
  else
    FStart := wsize;
  if num = 0 then
    FWidth := wsize div 2
  else
    FWidth := num;
end;

initialization

List := TObjectList<TFontClass>.Create;

finalization

List.Free;

end.
