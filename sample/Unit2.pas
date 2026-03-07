unit Unit2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, Thumbnails;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    ScrollBox1: TScrollBox;
    Thumbnails1: TThumbnails;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Thumbnails1Resize(Sender: TObject);
  private
    { private êÈåæ }
  public
    { public êÈåæ }
  end;

var
  Form2: TForm2;

implementation

{$R *.fmx}

procedure TForm2.Button1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    ScrollBox1.ViewportPosition := TPointF.Create(0, 0);
    Thumbnails1.Files.Assign(OpenDialog1.Files);
    Thumbnails1.Execute;
  end;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Thumbnails1.MinHeight := ScrollBox1.Height;
end;

procedure TForm2.Thumbnails1Resize(Sender: TObject);
begin
  ScrollBox1.Repaint;
end;

end.
