unit MusicReg;

interface

procedure Register;

implementation

uses Musiclyrics, Thumbnails, System.Classes;

procedure Register;
begin
  RegisterComponents('Kainushi', [TMusiclyrics, TThumbnails]);
end;

end.
