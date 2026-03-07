unit Thumbnails;

interface

uses
  System.SysUtils, System.Classes, System.Threading, System.Types, System.Math,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Layouts,
  FMX.Graphics, FMX.Controls.Presentation, FMX.StdCtrls;

type
  TThumbnails = class(TPanel)
  private
    { Private éŒ¾ }
    FInnerMargin: integer;
    FThumbnailSize: integer;
    FAutoSize: Boolean;
    FMinSize: Single;
  protected
    { Protected éŒ¾ }
    FTask: ITask;
    FBmps: TObjectList<TBitmap>;
    FFiles: TStrings;
    procedure Paint; override;
    procedure UpdateLayout(out ARects: TArray<TRectF>);
    function IsImageFile(const AFile: string): Boolean;
  public
    { Public éŒ¾ }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Cancel;
    procedure Clear;
    procedure Execute; virtual;
    function OpenFile(filename: string): Boolean; virtual;
    property Files: TStrings read FFiles write FFiles;
  published
    { Published éŒ¾ }
    property ThumbnailSize: integer read FThumbnailSize write FThumbnailSize;
    property AutoSize: Boolean read FAutoSize write FAutoSize;
    property InnerMargin: integer read FInnerMargin write FInnerMargin;
  end;

procedure Register;

implementation

uses System.UIConsts;

procedure Register;
begin
  RegisterComponents('Kainushi', [TThumbnails]);
end;

procedure TThumbnails.Cancel;
begin
  if Assigned(FTask) then
    FTask.Cancel;
end;

procedure TThumbnails.Clear;
begin
  FBmps.Clear;
  Repaint;
end;

constructor TThumbnails.Create(AOwner: TComponent);
begin
  inherited;
  FBmps := TObjectList<TBitmap>.Create;
  FFiles := TStringList.Create;
  FThumbnailSize := 100;
  FInnerMargin := 10;
  FMinSize := Height;
  FAutoSize := true;
end;

destructor TThumbnails.Destroy;
begin
  Cancel;
  FBmps.Free;
  FFiles.Free;
  inherited;
end;

procedure TThumbnails.Execute;
begin
  Cancel;
  FBmps.Clear;
  FTask := TTask.Run(
    procedure
    var
      cnt: integer;
      procedure count(i: integer);
      begin
        if cnt mod i = 0 then
          TThread.Synchronize(nil, Repaint);
      end;

    begin
      cnt := 0;
      for var name in FFiles do
        if OpenFile(name) then
        begin
          inc(cnt);
          count(5);
        end;
      TThread.Synchronize(nil, Repaint);
    end);
end;

function TThumbnails.IsImageFile(const AFile: string): Boolean;
const
  ext: array [0 .. 5] of string = ('.jpg', '.jpeg', '.png', '.tif',
    '.tiff', '.bmp');
var
  extlower: string;
begin
  extlower := ExtractFileExt(AFile).ToLower;
  for var s in ext do
    if s = extlower then
      Exit(true);
  result := false;
end;

function TThumbnails.OpenFile(filename: string): Boolean;
var
  bmp: TBitmap;
begin
  result := false;
  if not FileExists(filename) then
    Exit(false);
  if IsImageFile(filename) then
  begin
    bmp := TBitmap.Create(FThumbnailSize, FThumbnailSize);
    try
      FBmps.Add(bmp);
      bmp.LoadThumbnailFromFile(filename, FThumbnailSize,
        FThumbnailSize, false);
      result := true;
    except
      bmp.Free;
    end;
  end;
end;

procedure TThumbnails.Paint;
var
  r: TArray<TRectF>;
begin
  inherited;
  UpdateLayout(r);
  if Canvas.BeginScene then
    try
      for var i := 0 to High(r) do
        Canvas.DrawBitmap(FBmps[i], FBmps[i].BoundsF, r[i], 1, true);
      if FBmps.count = 0 then
      begin
        Canvas.Stroke.Thickness := 3;
        Canvas.DrawRect(TRectF.Create(FInnerMargin, FInnerMargin,
          FInnerMargin + FThumbnailSize, FInnerMargin + FThumbnailSize), 0,
          0, [], 1);
      end;
    finally
      Canvas.EndScene;
    end;
end;

procedure TThumbnails.UpdateLayout(out ARects: TArray<TRectF>);
var
  X, Y, tmp: Single;
  cnt: integer;
begin
  ARects := [];
  X := FInnerMargin;
  Y := FInnerMargin;
  tmp := 0;
  cnt := 0;
  for var bmp in FBmps do
  begin
    if (X + bmp.Width + FInnerMargin < Width) or (cnt = 0) then
    begin
      ARects := ARects + [TRectF.Create(X, Y, X + bmp.Width, Y + bmp.Height)];
      X := X + bmp.Width + FInnerMargin;
      tmp := Max(tmp, bmp.Height);
      inc(cnt);
    end
    else
    begin
      Y := Y + tmp + FInnerMargin;
      tmp := bmp.Height;
      cnt := 0;
      ARects := ARects + [TRectF.Create(X, Y, X + bmp.Width, Y + bmp.Height)];
    end;
  end;
  if (FBmps.count > 0) and FAutoSize then
;//    Height := Max(Y + tmp + FInnerMargin, FMinSize);
end;

end.
