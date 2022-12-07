program TSQLExample;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {FmMain},
  DataLoader in 'DataLoader.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
    ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFmMain, FmMain);
  Application.Run;
end.
