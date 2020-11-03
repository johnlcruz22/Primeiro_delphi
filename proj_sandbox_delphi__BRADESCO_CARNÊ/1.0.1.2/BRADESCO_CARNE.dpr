program BRADESCO_CARNE;

uses
  Forms,
  uMain in 'uMain.pas' {frmMain},
  ucore in 'ucore.pas',
  udatatypes_apps in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\udatatypes_apps.pas',
  ClassLog in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassLog.pas',
  ClassDirectory in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassDirectory.pas',
  ClassStrings in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassStrings.pas',
  ClassTextFile in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassTextFile.pas',
  ClassIni in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassIni.pas',
  ClassMySqlBases in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassMySqlBases.pas',
  ClassConexoes in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassConexoes.pas',
  ClassConf in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassConf.pas',
  ClassArquivoIni in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassArquivoIni.pas',
  ClassFuncoesWin in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassFuncoesWin.pas',
  ClassLayoutArquivo in 'ClassLayoutArquivo.pas',
  ClassBlocaInteligente in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassBlocaInteligente.pas',
  ClassParametrosDeEntrada in 'ClassParametrosDeEntrada.pas',
  ClassFuncoesBancarias in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassFuncoesBancarias.pas',
  ClassPlanoDeTriagem in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassPlanoDeTriagem.pas',
  ClassExpressaoRegular in '..\..\classes-delphi__fingerprint_cpd_desenvolvimento\ClassExpressaoRegular.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'proj-sandbox-delphi__esqueleto_para_criacao_de_programas';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
