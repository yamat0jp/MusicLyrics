unit Thumbnails;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Objects,
  FMX.Graphics, System.Threading, System.Generics.Collections, System.Types,
  System.Math, FMX.Layouts, FMX.StdCtrls;

type
  TPageCountEvent = procedure(Sender: TObject; cnt: integer) of object;

  TThumbnails = class(TScrollBox)
  private
    { Private éŒ¾ }
    FInnerMargin: integer;
    FThumbnailSize: integer;
    FOnLoadFile: TPageCountEvent;
    procedure SetThumbnailSize(const Value: integer);
  protected
    { Protected éŒ¾ }
    FTask: ITask;
    FImages: TObjectList<TImage>;
    FLabels: TObjectList<TLabel>;
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
    function OpenFile(filename: string; out data: TPair<TImage, TLabel>)
      : Boolean; virtual;
    property Files: TStrings read FFiles write FFiles;
  published
    { Published éŒ¾ }
    property ThumbnailSize: integer read FThumbnailSize write SetThumbnailSize;
    property InnerMargin: integer read FInnerMargin write FInnerMargin;
    property OnLoadFile: TPageCountEvent read FOnLoadFile write FOnLoadFile;
  end;

implementation

uses System.UITypes;

{ TThumbnails }

procedure TThumbnails.Cancel;
begin
  if Assigned(FTask) then
  begin
    FTask.Cancel;
    FTask := nil;
  end;
end;

procedure TThumbnails.Clear;
begin
  FImages.Clear;
  Repaint;
end;

constructor TThumbnails.Create(AOwner: TComponent);
begin
  inherited;
  FImages := TObjectList<TImage>.Create;
  FLabels := TObjectList<TLabel>.Create;
  FFiles := TStringList.Create;
  FThumbnailSize := 100;
  FInnerMargin := 10;
end;

destructor TThumbnails.Destroy;
begin
  Cancel;
  FImages.Free;
  FLabels.Free;
  FFiles.Free;
  inherited;
end;

procedure TThumbnails.Execute;
begin
  Cancel;
  FImages.Clear;
  FLabels.Clear;
  FTask := TTask.Run(
    procedure
    var
      pair: TPair<TImage, TLabel>;
      procedure main(id: integer);
      begin
        TThread.Synchronize(nil,
          procedure
          begin
            FImages.add(pair.Key);
            FLabels.add(pair.Value);
            pair.Key.Parent := Self;
            pair.Value.Parent := Self;
            if Assigned(FOnLoadFile) then
              FOnLoadFile(Self, id);
          end);
      end;

    begin
      for var i := 0 to (FFiles.Count div 5) - 1 do
      begin
        for var k := 5 * i to 5 * i + 4 do
          if TTask.CurrentTask.Status = TTaskStatus.Canceled then
            Exit
          else if OpenFile(FFiles[k], pair) then
            main(k + 1);
        TThread.Synchronize(nil, Repaint);
      end;
      for var i := FFiles.Count - (FFiles.Count mod 5) to FFiles.Count - 1 do
        if OpenFile(FFiles[i], pair) then
          main(i + 1);
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

function TThumbnails.OpenFile(filename: string;
out data: TPair<TImage, TLabel>): Boolean;
var
  img: TImage;
  lb: TLabel;
  setting: TTextSettings;
begin
  if FileExists(filename) and IsImageFile(filename) then
  begin
    lb := TLabel.Create(Self);
    lb.Text := ExtractFileName(filename);
    lb.StyledSettings := [TStyledSetting.Family, TStyledSetting.Size];
    setting := lb.TextSettings;
    setting.WordWrap := false;
    setting.FontColor := TAlphaColors.Indianred;
    setting.Font.Style := [TFontStyle.fsBold];
    data.Value := lb;
    img := TImage.Create(Self);
    try
      img.Width := FThumbnailSize;
      img.Height := FThumbnailSize;
      img.Bitmap.LoadThumbnailFromFile(filename, FThumbnailSize,
        FThumbnailSize, false);
      data.Key := img;
      result := true;
    except
      img.Free;
      lb.Free;
      result := false;
    end;
  end
  else
    result := false;
end;

procedure TThumbnails.Paint;
var
  r: TArray<TRectF>;
begin
  inherited;
  if FImages.Count <> FLabels.Count then
    Exit;
  UpdateLayout(r);
  if Canvas.BeginScene then
    try
      for var i := 0 to High(r) do
      begin
        with FImages[i].Position do
        begin
          X := r[i].Left;
          Y := r[i].Top;
        end;
        with FLabels[i].Position do
        begin
          X := r[i].Left;
          Y := r[i].Top;
        end;
        FLabels[i].Width := FImages[i].Width;
      end;
    finally
      Canvas.EndScene;
    end;
end;

procedure TThumbnails.SetThumbnailSize(const Value: integer);
begin
  if FThumbnailSize <> Value then
  begin
    FThumbnailSize := Value;
    Execute;
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
  for var bmp in FImages do
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
      X := FInnerMargin;
      Y := Y + tmp + FInnerMargin;
      tmp := bmp.Height;
      cnt := 0;
      ARects := ARects + [TRectF.Create(X, Y, X + bmp.Width, Y + bmp.Height)];
      X := X + bmp.Width + FInnerMargin;
    end;
  end;
end;

end.
