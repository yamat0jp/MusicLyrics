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
    { Private 宣言 }
    FInnerMargin: integer;
    FThumbnailSize: Single;
    FOnLoadFile: TPageCountEvent;
    procedure SetThumbnailSize(const Value: Single);
    procedure AddUI(const text: string);
  protected
    { Protected 宣言 }
    FTask: ITask;
    FImages: TObjectList<TImage>;
    FFiles: TStrings;
    procedure UpdateLayout(out ARects: TArray<TRectF>);
    function IsImageFile(const AFile: string): Boolean;
    procedure Resize; override;
  public
    { Public 宣言 }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Cancel;
    procedure Clear;
    procedure Execute; virtual;
    property Files: TStrings read FFiles write FFiles;
  published
    { Published 宣言 }
    property ThumbnailSize: Single read FThumbnailSize write SetThumbnailSize;
    property InnerMargin: integer read FInnerMargin write FInnerMargin;
    property OnLoadFile: TPageCountEvent read FOnLoadFile write FOnLoadFile;
  end;

implementation

uses System.UITypes;

{ TThumbnails }

procedure TThumbnails.AddUI(const text: string);
var
  img: TImage;
  lb: TLabel;
  setting: TTextSettings;
begin
  if not FileExists(text) or not IsImageFile(text) then
    raise Exception.Create('エラー メッセージ');
  img := TImage.Create(Self);
  try
    lb := TLabel.Create(img);
    img.TagObject := lb;
    img.TagString := text;
    lb.Position.X := 0;
    lb.Position.Y := 0;
    lb.Parent := img;
    lb.text := ExtractFileName(text);
    lb.StyledSettings := [TStyledSetting.Family, TStyledSetting.Size];
    setting := lb.TextSettings;
    setting.WordWrap := false;
    setting.FontColor := TAlphaColors.Indianred;
    setting.Font.Style := [TFontStyle.fsBold];
    FImages.Add(img);
  except
    img.Free;
  end;
end;

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
  FFiles := TStringList.Create;
  FThumbnailSize := 100;
  FInnerMargin := 10;
end;

destructor TThumbnails.Destroy;
begin
  Cancel;
  FImages.Free;
  FFiles.Free;
  inherited;
end;

procedure TThumbnails.Execute;
begin
  Cancel;
  FImages.Clear;
  FTask := TTask.Run(
    procedure
    var
      r: TArray<TRectF>;
      cnt, k: integer;
    label back;
    begin
      cnt := 0;
      while cnt < FFiles.Count do
        try
          k := cnt;
        back:
          if TTask.CurrentTask.Status = TTaskStatus.Canceled then
            Exit
          else
            TThread.Synchronize(nil,
              procedure
              begin
                AddUI(FFiles[cnt])
              end);
          inc(cnt);
          if (cnt - k < 5) and (cnt < FFiles.Count) then
            goto back;
        finally
          UpdateLayout(r);
          TParallel.For(k, cnt - 1,
            procedure(i: integer)
            begin
              FImages[i].Bitmap.LoadThumbnailFromFile(FImages[i].TagString,
                r[i].Width, r[i].Height, false);
            end);
          TThread.Synchronize(nil,
            procedure
            begin
              for var i := k to cnt - 1 do
              begin
                FImages[i].SetBounds(r[i].Left, r[i].Top, r[i].Width,
                  r[i].Height);
                FImages[i].Parent := Self;
                if Assigned(FOnLoadFile) then
                  FOnLoadFile(FImages[i], i);
              end;
              Repaint;
            end);
        end;
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

procedure TThumbnails.Resize;
var
  r: TArray<TRectF>;
begin
  inherited;
  UpdateLayout(r);
  for var i := 0 to FImages.Count - 1 do
    with FImages[i].Position do
    begin
      X := r[i].Left;
      Y := r[i].Top;
    end;
  Repaint;
end;

procedure TThumbnails.SetThumbnailSize(const Value: Single);
begin
  if FThumbnailSize <> Value then
  begin
    FThumbnailSize := Value;
    Execute;
  end;
end;

procedure TThumbnails.UpdateLayout(out ARects: TArray<TRectF>);
var
  X, Y: Single;
  cnt, i: integer;
begin
  ARects := [];
  X := FInnerMargin;
  Y := FInnerMargin;
  cnt := 0;
  i := 0;
  while i < FFiles.Count do
  begin
    if (X + FThumbnailSize + FInnerMargin < Width) or (cnt = 0) then
    begin
      ARects := ARects + [TRectF.Create(X, Y, X + FThumbnailSize,
        Y + FThumbnailSize)];
      X := X + FThumbnailSize + FInnerMargin;
      inc(cnt);
    end
    else
    begin
      X := FInnerMargin;
      Y := Y + FThumbnailSize + FInnerMargin;
      cnt := 0;
      continue;
    end;
    inc(i);
  end;
end;

end.
