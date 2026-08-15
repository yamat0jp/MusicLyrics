unit MusicReg;

interface

procedure Register;

implementation

uses Musiclyrics, Thumbnails, FMXDotMess, System.Classes;

procedure Register;
begin
  RegisterComponents('Kainushi', [TMusiclyrics, TThumbnails, TFMXDotMess]);
end;

end.
