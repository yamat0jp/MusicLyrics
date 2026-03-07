unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, MusicLyrics, FMX.Media;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    MediaPlayer1: TMediaPlayer;
    Button1: TButton;
    Timer1: TTimer;
    StyleBook1: TStyleBook;
    MusicLyrics1: TMusicLyrics;
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private êÈåæ }
  public
    { public êÈåæ }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
begin
  if MediaPlayer1.State = TMediaState.Playing then
  begin
    MediaPlayer1.Stop;
    MediaPlayer1.CurrentTime := 0;
  end;
  MediaPlayer1.Play;
  MusicLyrics1.FileOpen(MediaPlayer1.FileName);
  Timer1.Enabled := true;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  MediaPlayer1.FileName := 'E:\fuke\GitHub\MusicLyrics\Lyrics\03 Ç©ÇΩÇøÇ†ÇÈÇ‡ÇÃ.mp3';
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  MusicLyrics1.SyncLyrics(MediaPlayer1.CurrentTime / MediaTimeScale);
end;

end.
