unit MusicReg;

interface

procedure Register;

implementation

uses Musiclyrics, Thumbnails, DotMessage, System.Classes;

procedure Register;
begin
  RegisterComponents('Kainushi', [TMusiclyrics, TThumbnails, TDotMessage]);
end;

end.
