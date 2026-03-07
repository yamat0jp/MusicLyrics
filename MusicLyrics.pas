unit MusicLyrics;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Layouts,
  FMX.StdCtrls;

type
  TLyricLine = record
    TimeMs: Integer;
    Text: string;
    LabelCtrl: TLabel;
  end;

  TMusicLyrics = class(TScrollBox)
  private
    { Private 宣言 }
    FCurrentIndex: Integer;
    procedure ParseLRC(const FileName: string; out Lyrics: TArray<TLyricLine>);
    procedure BuildLyricsUI(const Lyrics: TArray<TLyricLine>);
    procedure ScrollToCenter(Index: Integer);
  protected
    { Protected 宣言 }
    FLyrics: TArray<TLyricLine>;
    procedure HighlightLyric(Index: Integer); virtual;
    // property Lyrics[X: integer]: TLyricLine;
  public
    { Public 宣言 }
    procedure FileOpen(FileName: string);
    procedure SyncLyrics(CurrentTime: Single);
    property CurrentIndex: Integer read FCurrentIndex;
  published
    { Published 宣言 }
  end;

implementation

uses System.Generics.Collections, System.Generics.Defaults, FMX.Objects,
  FMX.Ani;

{ TMusicLyrics }

procedure TMusicLyrics.BuildLyricsUI(const Lyrics: TArray<TLyricLine>);
var
  T: TText;
  LineHeight: Single;
begin
  // 既存のコントロールを削除
  for var i := Content.ChildrenCount - 1 downto 0 do
    Content.Children[i].Free;

  // Spotify風の行間
  LineHeight := 40;

  for var i := 0 to High(Lyrics) do
  begin
    T := TText.Create(Self);
    T.Parent := Content;

    // 歌詞テキスト
    T.Text := Lyrics[i].Text;

    // Spotify風スタイル
    T.TextSettings.HorzAlign := TTextAlign.Center;
    T.TextSettings.Font.Size := 22;
    T.TextSettings.FontColor := $FFAAAAAA; // 淡色
    T.WordWrap := True;

    // 横幅いっぱいに広げる
    T.Position.X := 20;
    T.Width := Width - 40;

    // 縦位置（行間広め）
    T.Position.Y := Height + i * LineHeight;

    // 後で同期処理で使うために Tag にインデックスを入れておく
    T.Tag := i;
  end;
end;

procedure TMusicLyrics.FileOpen(FileName: string);
begin
  if LowerCase(ExtractFileExt(FileName)) <> '.lrc' then
    FileName := ChangeFileExt(FileName, '.lrc');
  ParseLRC(FileName, FLyrics);
  BuildLyricsUI(FLyrics);
  FCurrentIndex := -1;
end;

procedure TMusicLyrics.HighlightLyric(Index: Integer);
var
  T: TText;
  Anim: TFloatAnimation;
begin
  if Index < 0 then
    Exit;

  // すべての行を淡色に戻す
  for var i := 0 to Content.ChildrenCount - 1 do
  begin
    if Content.Children[i] is TText then
    begin
      T := TText(Content.Children[i]);
      T.TextSettings.FontColor := $FFAAAAAA; // 淡色
      T.Opacity := 1.0; // 不透明に戻す
    end;
  end;

  // 現在行の TText を取得
  T := TText(Content.Children[Index]);

  // 白色に変更
  T.TextSettings.FontColor := $FFFFFFFF;

  // フェードアニメーションを設定
  T.Opacity := 0.0; // 最初は透明

  Anim := TFloatAnimation.Create(T);
  Anim.Parent := T;
  Anim.PropertyName := 'Opacity';
  Anim.StartValue := 0.0;
  Anim.StopValue := 1.0;
  Anim.Duration := 0.25; // 250ms
  Anim.Interpolation := TInterpolationType.Cubic;
  Anim.Start;
end;

procedure TMusicLyrics.ParseLRC(const FileName: string;
  out Lyrics: TArray<TLyricLine>);
var
  SL: TStringList;
  p, OffsetValue: Integer;
  Line, Tag, Text: string;
  Min, Sec, Ms: Integer;
  TimeList: TList<Integer>;
  LyricList: TList<TLyricLine>;
  L: TLyricLine;
begin
  SL := TStringList.Create;
  TimeList := TList<Integer>.Create;
  LyricList := TList<TLyricLine>.Create;
  OffsetValue := 0;

  try
    SL.LoadFromFile(FileName, TEncoding.UTF8);

    for var i := 0 to SL.Count - 1 do
    begin
      Line := Trim(SL[i]);
      if Line = '' then
        Continue;
      if Line.StartsWith(';') then
        Continue; // コメント行

      // メタデータ処理
      if Line.StartsWith('[ti:') or Line.StartsWith('[ar:') or
        Line.StartsWith('[al:') or Line.StartsWith('[by:') then
        Continue;

      // offset
      if Line.StartsWith('[offset:') then
      begin
        OffsetValue := StrToIntDef(Copy(Line, 9, Length(Line) - 9), 0);
        Continue;
      end;

      // タイムタグが複数ある場合に対応
      TimeList.Clear;
      p := 1;

      while (p < Length(Line)) and (Line[p] = '[') do
      begin
        Tag := Copy(Line, p + 1, 8); // mm:ss.xx
        Min := StrToIntDef(Copy(Tag, 1, 2), 0);
        Sec := StrToIntDef(Copy(Tag, 4, 2), 0);
        Ms := StrToIntDef(Copy(Tag, 7, 2), 0) * 10;

        TimeList.Add(Min * 60000 + Sec * 1000 + Ms);

        // 次のタグへ
        p := p + 10;
      end;

      // 歌詞部分
      Text := Trim(Copy(Line, p, MaxInt));

      // タイムタグがない行は無視
      if TimeList.Count = 0 then
        Continue;

      // タイムタグが複数ある場合は複製
      for var T in TimeList do
      begin
        L.TimeMs := T + OffsetValue;
        L.Text := Text;
        LyricList.Add(L);
      end;
    end;

    // 時間順にソート
    LyricList.Sort(TComparer<TLyricLine>.Construct(
      function(const A, B: TLyricLine): Integer
      begin
        Result := A.TimeMs - B.TimeMs;
      end));

    // 配列に変換
    Lyrics := LyricList.ToArray;

  finally
    SL.Free;
    TimeList.Free;
    LyricList.Free;
  end;
end;

procedure TMusicLyrics.ScrollToCenter(Index: Integer);
var
  T: TText;
  TargetY: Single;
begin
  T := TText(Content.Children[Index]);

  // ラベルの中央が画面中央に来るように計算
  TargetY := T.Position.Y - (Height / 2) + (T.Height / 2);

  AniCalculations.Animation := True;
  ScrollBy(0, ViewPortPosition.Y - TargetY);
end;

procedure TMusicLyrics.SyncLyrics(CurrentTime: Single);
begin
  for var i := 0 to High(FLyrics) do
    if (CurrentTime * 1000 >= FLyrics[i].TimeMs) and (FCurrentIndex < i) then
    begin
      FCurrentIndex := i;
      HighlightLyric(FCurrentIndex);
      ScrollToCenter(FCurrentIndex);
    end;
end;

end.
