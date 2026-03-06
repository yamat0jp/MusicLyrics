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
    FSize: integer;
  protected
    { Protected éŒ¾ }
    FTask: ITask;
    FBmps: TObjectList<TBitmap>;
    FFiles: TStrings;
    FMaxHeight: Single;
    procedure Paint; override;
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
    property Size: integer read FSize write FSize;
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
  FSize := 100;
  FInnerMargin := 10;
  Align := TAlignLayout.Top;
  if Assigned(ParentControl) then
  begin
    Height := ParentControl.Height;
    FMaxHeight := ParentControl.Height;
  end;
end;

destructor TThumbnails.Destroy;
begin
  FBmps.Free;
  FFiles.Free;
  Cancel;
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
    bmp := TBitmap.Create(FSize, FSize);
    try
      FBmps.Add(bmp);
      bmp.LoadThumbnailFromFile(filename, FSize, FSize, false);
      result := true;
    except
      bmp.Free;
    end;
  end;
end;

procedure TThumbnails.Paint;
var
  X, Y, max: Single;
  procedure PaintRect(bmp: TBitmap);
  var
    rect: TRectF;
  begin
    rect := TRectF.Create(X, Y, X + bmp.Width, Y + bmp.Height);
    Canvas.DrawBitmap(bmp, bmp.BoundsF, rect, 1, true);
  end;

begin
  inherited;
  if Assigned(ParentControl) then
    Height := System.Math.max(FMaxHeight, ParentControl.Height);
  X := FInnerMargin;
  Y := FInnerMargin;
  max := 0;
  if Canvas.BeginScene then
    try
      for var bmp in FBmps do
        if X + bmp.Width < Width then
        begin
          PaintRect(bmp);
          X := X + bmp.Width + FInnerMargin;
          max := System.Math.max(max, bmp.Height);
        end
        else
        begin
          X := FInnerMargin;
          Y := Y + max + FInnerMargin;
          max := bmp.Height;
          PaintRect(bmp);
        end;
      if FBmps.count = 0 then
      begin
        Canvas.Stroke.Thickness := 3;
        Canvas.DrawRect(TRectF.Create(FInnerMargin, FInnerMargin,
          FInnerMargin + FSize, FInnerMargin + FSize), 0, 0, [], 1);
      end;
    finally
      Canvas.EndScene;
    end;
  FMaxHeight := Y + max + FInnerMargin;
end;

end.
