unit ImgsShow;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Layouts,
  FMX.Graphics, System.Threading;

type
  TImgsScrollBox = class(TVertScrollBox)
  private
    FInnerMargin: integer;
    FSize: integer;
    [weak]
    FTask: ITask;
    { Private éŒ¾ }
  protected
    { Protected éŒ¾ }
    FFiles: TStrings;
    FBmps: TArray<TBitmap>;
    function OpenFile(filename: string): Boolean;
    procedure Clear;
    property Task: ITask read FTask write FTask;
  public
    { Public éŒ¾ }
    procedure Execute; virtual;
    procedure Cancel;
    procedure Paint; override;
  published
    { Published éŒ¾ }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Files: TStrings read FFiles;
    property InnerMargin: integer read FInnerMargin write FInnerMargin;
    property Size: integer read FSize write FSize;
  end;

procedure Register;

implementation

uses System.Types;

procedure Register;
begin
  RegisterComponents('Kainushi', [TImgsScrollBox]);
end;

{ TImgsScrollBox }

procedure TImgsScrollBox.Cancel;
begin
  if Assigned(FTask) then
    FTask.Cancel;
end;

procedure TImgsScrollBox.Clear;
begin
  for var bmp in FBmps do
    bmp.Free;
  FBmps := [];
end;

constructor TImgsScrollBox.Create(AOwner: TComponent);
begin
  inherited;
  FFiles := TStringList.Create;
  FSize := 100;
  FInnerMargin := 10;
  ClipChildren := true;
end;

destructor TImgsScrollBox.Destroy;
begin
  Clear;
  FFiles.Free;
  Cancel;
  inherited;
end;

procedure TImgsScrollBox.Execute;
var
  cnt: integer;
begin
  Cancel;
  Clear;
  cnt := 0;
  FTask := TTask.Run(
    procedure
    begin
      for var name in FFiles do
        if OpenFile(name) then
        begin
          inc(cnt);
          if cnt mod 5 = 0 then
            Repaint;
        end;
      Repaint;
    end);
end;

function TImgsScrollBox.OpenFile(filename: string): Boolean;
var
  bmp: TBitmap;
begin
  for var str in ['.jpg', '.jpeg', '.png', '.tif', '.tiff', '.bmp'] do
    if FileExists(filename) and (ExtractFileExt(filename).ToLower = str) then
    begin
      bmp := TBitmap.Create(FSize, FSize);
      FBmps := FBmps + [bmp];
      bmp.LoadThumbnailFromFile(filename, FSize, FSize, false);
      Exit(true);
    end;
  result := false;
end;

procedure TImgsScrollBox.Paint;
var
  X, Y, max: Single;
begin
  inherited;
  X := FInnerMargin;
  Y := FInnerMargin;
  max := 0;
  for var bmp in FBmps do
  begin
    if max < bmp.Height then
      max := bmp.Height;
    if X + bmp.Width < Width then
    begin
      Canvas.DrawBitmap(bmp, bmp.Bounds, TRectF.Create(X, Y, X + bmp.Width,
        Y + bmp.Height), 1, true);
      X := X + bmp.Width + FInnerMargin;
    end
    else
    begin
      X := FInnerMargin;
      Y := Y + max + FInnerMargin;
      max := bmp.Height;
      Content.Height := Y + bmp.Height + FInnerMargin;
      Canvas.DrawBitmap(bmp, bmp.Bounds, TRectF.Create(X, Y, X + bmp.Width,
        Y + bmp.Height), 1, true);
    end;
  end;
end;

end.
