unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.Generics.Collections, System.Generics.Defaults;

type
  TForm7 = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure Edit1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form7: TForm7;

implementation

uses
  IntervalStr;

{$R *.dfm}

procedure TForm7.Edit1Change(Sender: TObject);
var
  I: UInt64;
begin
  if TryIntervalStrToMSec(Edit1.Text, I, TIntervalUnits.Default) then
  begin
    Label1.Caption := I.ToString;
    Label2.Caption := MSecToIntervalStr(I, TIntervalUnits.Default);
    Label3.Caption := IntToStr(IntervalStrToMSec(Label2.Caption));
  end
  else
    Label1.Caption := 'Error';
end;

end.
