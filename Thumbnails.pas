unit Thumbnails;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Objects,
  FMX.Graphics, System.Threading, System.Generics.Collections, System.Types,
  System.Math, FMX.Layouts, FMX.StdCtrls;

type
  TPageCountEvent = procedure(Sender: TObject; cnt: integer) of object;

  TThumbnails = class(TPaintBox)
  private
    { Private éŒ¾ }
    FInnerMargin: integer;
    FThumbnailSize: integer;
    FAutoSize: Boolean;
    FMinHeight: Single;
    FOnLoadFile: TPageCountEvent;
    procedure SetThumbnailSize(const Value: integer);
  protected
    { Protected éŒ¾ }
    FTask: ITask;
    FBmps: TObjectList<TBitmap>;
    FLabels: TObjectList<TLabel>;
    FFiles: TStrings;
    procedure Paint; override;
    procedure UpdateLayout(out ARects: TArray<TRectF>);
    function IsImageFile(const AFile: string): Boolean;
    procedure Resize; override;
  public
    { Public éŒ¾ }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Cancel;
    procedure Clear;
    procedure Execute; virtual;
    function OpenFile(filename: string; out data: TPair<TBitmap, TLabel>)
      : Boolean; virtual;
    property Files: TStrings read FFiles write FFiles;
  published
    { Published éŒ¾ }
    property ThumbnailSize: integer read FThumbnailSize write SetThumbnailSize;
    property AutoSize: Boolean read FAutoSize write FAutoSize;
    property InnerMargin: integer read FInnerMargin write FInnerMargin;
    property MinHeight: Single read FMinHeight write FMinHeight;
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
  FBmps.Clear;
  Repaint;
end;

constructor TThumbnails.Create(AOwner: TComponent);
begin
  inherited;
  FBmps := TObjectList<TBitmap>.Create;
  FLabels := TObjectList<TLabel>.Create;
  FFiles := TStringList.Create;
  FThumbnailSize := 100;
  FInnerMargin := 10;
  FMinHeight := 600;
  FAutoSize := true;
end;

destructor TThumbnails.Destroy;
begin
  Cancel;
  FBmps.Free;
  FLabels.Free;
  FFiles.Free;
  inherited;
end;

procedure TThumbnails.Execute;
begin
  Cancel;
  FBmps.Clear;
  FLabels.Clear;
  FTask := TTask.Run(
    procedure
    var
      pair: TPair<TBitmap, TLabel>;
      procedure main(id: integer);
      begin
        TThread.Synchronize(nil,
          procedure
          begin
            FBmps.add(pair.Key);
            FLabels.add(pair.Value);
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
out data: TPair<TBitmap, TLabel>): Boolean;
var
  bmp: TBitmap;
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
    lb.Parent := Self;
    data.Value := lb;
    bmp := TBitmap.Create(FThumbnailSize, FThumbnailSize);
    try
      bmp.LoadThumbnailFromFile(filename, FThumbnailSize,
        FThumbnailSize, false);
      data.Key := bmp;
      result := true;
    except
      bmp.Free;
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
  if FBmps.Count <> FLabels.Count then
    Exit;
  UpdateLayout(r);
  if Canvas.BeginScene then
    try
      for var i := 0 to High(r) do
      begin
        Canvas.DrawBitmap(FBmps[i], FBmps[i].BoundsF, r[i], 1, true);
        with FLabels[i].Position do
        begin
          X := r[i].Left;
          Y := r[i].Top;
        end;
        FLabels[i].Width := FBmps[i].Width;
      end;
    finally
      Canvas.EndScene;
    end;
end;

procedure TThumbnails.Resize;
begin
  inherited;
  if Height < FMinHeight then
    Height := FMinHeight;
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
      X := FInnerMargin;
      Y := Y + tmp + FInnerMargin;
      tmp := bmp.Height;
      cnt := 0;
      ARects := ARects + [TRectF.Create(X, Y, X + bmp.Width, Y + bmp.Height)];
      X := X + bmp.Width + FInnerMargin;
    end;
  end;
  if FAutoSize then
    Height := Max(Y + tmp + FInnerMargin, FMinHeight);
end;

end.
