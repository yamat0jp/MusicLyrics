unit FMXDotMess;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Objects,
  FMX.Graphics, FMX.Memo, BaseMessage;

type
  TFMXDotMess = class(TPaintBox)
  private
    FSize: Single;
    FLoop: Boolean;
    FLines: TMemo;
    FTimer: TTimer;
    FActive: Boolean;
    procedure SetActive(const Value: Boolean);
    { Private 宣言 }
  protected
    { Protected 宣言 }
    procedure Paint; override;
    procedure Resize; override;
  public
    { Public 宣言 }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Execute; virtual;
    class procedure Filter(ABmp: TBitmap; out AData: TFontData); static;
    procedure TimerOnTimer(Sender: TObject); dynamic;
  published
    { Published 宣言 }
    property Lines: TMemo read FLines write FLines;
    property Loop: Boolean read FLoop write FLoop;
    property Active: Boolean read FActive write SetActive;
  end;

implementation

uses System.UITypes, System.Types, System.Threading, System.Math;

{ TFMXDotMess }

constructor TFMXDotMess.Create(AOwner: TComponent);
begin
  inherited;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 120;
  FTimer.OnTimer := TimerOnTimer;
  Active := false;
  Resize;
end;

destructor TFMXDotMess.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TFMXDotMess.Execute;
var
  bmp: TBitmap;
  data: TFontData;
  hei: integer;
begin
  hei := Round(Height);
  bmp := TBitmap.Create(hei, hei);
  try
    for var ch in FLines.Text do
    begin
      if Chars[ch] = nil then
        with bmp.Canvas do
        begin
          BeginScene;
          Clear(TAlphaColors.Black);
          Font.Size := hei;
          Font.Style := [TFontStyle.fsBold];
          Fill.Color := TAlphaColors.White;
          FillText(bmp.Bounds, ch, false, 1.0, [], TTextAlign.Center);
          EndScene;
          TFMXDotMess.Filter(bmp, data);
          Chars[ch] := data;
        end;
      List.Add(TFontClass.Create(Chars[ch]));
    end;
  finally
    bmp.Free;
  end;
  FTimer.Enabled := true;
end;

class procedure TFMXDotMess.Filter(ABmp: TBitmap; out AData: TFontData);
var
  DataMap: TBitmapData;
  RGB: TAlphaColorRec;
  bx, by: integer;
  R, G, B: Int64;
  SizeInt: integer;
  row: PAlphaColor;
  sum: array of array of TRGBCollection;
  cnt: array of array of integer;
begin
  SetLength(sum, wsize, hsize);
  SetLength(cnt, wsize, hsize);
  SetLength(AData, wsize, hsize);
  SizeInt := ABmp.Height div hsize;

  // FMXではMapを使用してピクセルデータにアクセスする
  if ABmp.Map(TMapAccess.Read, DataMap) then
    try
      for var y := 0 to ABmp.Height - 1 do
      begin
        row := DataMap.GetScanline(y);
        for var x := 0 to ABmp.Width - 1 do
        begin
          RGB := TAlphaColorRec.Create(row^);
          inc(row);

          if (RGB.R + RGB.G + RGB.B) div 3 < 50 then
            continue;

          // どのブロックか
          bx := Min(x div SizeInt, wsize - 1);
          by := Min(y div SizeInt, hsize - 1);

          sum[bx, by].R := sum[bx, by].R + RGB.R;
          sum[bx, by].G := sum[bx, by].G + RGB.G;
          sum[bx, by].B := sum[bx, by].B + RGB.B;
          cnt[bx, by] := cnt[bx, by] + 1;
        end;
      end;
    finally
      ABmp.Unmap(DataMap);
    end;

  // 平均値を計算して格納
  for bx := 0 to wsize - 1 do
    for by := 0 to hsize - 1 do
    begin
      if cnt[bx, by] = 0 then
      begin
        AData[bx, by] := TAlphaColors.Black;
        continue;
      end;

      R := Min(sum[bx, by].R div cnt[bx, by], 255);
      G := Min(sum[bx, by].G div cnt[bx, by], 255);
      B := Min(sum[bx, by].B div cnt[bx, by], 255);

      RGB.A := 255;
      RGB.R := R;
      RGB.G := G;
      RGB.B := B;
      AData[bx, by] := RGB.Color;
    end;
end;

procedure TFMXDotMess.Paint;
var
  obj: TFontClass;
  st: Single;
  rf: TRectF;
begin
  inherited;
  Canvas.Clear(TAlphaColors.Gray);
  for var k := List.Count - 1 downto 0 do
  begin
    obj := List[k];
    if obj.Start * FSize > Width then
      continue;
    st := obj.Start;
    for var i := 0 to obj.Width do
      for var j := 0 to hsize - 1 do
      begin
        rf := TRectF.Create((i + st) * FSize, j * FSize, (i + st + 1) * FSize,
          (j + 1) * FSize);
        Canvas.Fill.Color := obj.data[i, j];
        Canvas.FillEllipse(rf, 1.0);
      end;
  end;
end;

procedure TFMXDotMess.Resize;
begin
  inherited;
  FSize := Height / hsize;
end;

procedure TFMXDotMess.SetActive(const Value: Boolean);
begin
  FActive := Value;
  FTimer.Enabled := Value;
end;

procedure TFMXDotMess.TimerOnTimer(Sender: TObject);
var
  obj: TFontClass;
begin
  for var i := List.Count - 1 downto 0 do
  begin
    obj := List[i];
    obj.Start := obj.Start - 1;
    if obj.Start + obj.Width < 0 then
      List.Delete(i);
  end;
  if List.Count < Length(FLines.Text) then
    Execute;
  InvalidateRect(BoundsRect);
end;

end.
