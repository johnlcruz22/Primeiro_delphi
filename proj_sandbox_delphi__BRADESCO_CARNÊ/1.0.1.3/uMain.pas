unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, FileCtrl,
  Dialogs, StdCtrls, Buttons, Mask, JvExMask, JvToolEdit,
  udatatypes_apps, ucore, ComCtrls, CheckLst, ZAbstractDataset, ZDataset,
  ExtCtrls, ClassParametrosDeEntrada, ClassExpressaoRegular;

type

  TfrmMain = class(TForm)
    btnSobre: TBitBtn;
    btnSair: TBitBtn;
    pgcMain: TPageControl;
    tbsEntrada: TTabSheet;
    tbsSaida: TTabSheet;
    tbsExecutar: TTabSheet;
    btnExecutar: TBitBtn;
    lblCaminhoArquivosEntrada: TLabel;
    btnSelecionarTodos: TBitBtn;
    btnLimparSelecao: TBitBtn;
    cltArquivos: TCheckListBox;
    lblInfos: TLabel;
    lblCaminhoArquivosSaida: TLabel;
    edtPathEntrada: TEdit;
    btnSelecionarPath: TSpeedButton;
    edtPathSaida: TEdit;
    btnSelecionarPathSaida: TSpeedButton;
    lblIdProcessamento: TLabel;
    lblIdProcessamentoValor: TLabel;
    procedure btnSairClick(Sender: TObject);
    procedure btnSobreClick(Sender: TObject);
    procedure btnExecutarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSelecionarTodosClick(Sender: TObject);
    procedure btnLimparSelecaoClick(Sender: TObject);
    procedure cltArquivosClick(Sender: TObject);
    procedure btnSelecionarPathClick(Sender: TObject);
    procedure edtPathEntradaChange(Sender: TObject);
    procedure btnSelecionarPathSaidaClick(Sender: TObject);

  private
    { Private declarations }

    {
      Variável privada que contêm todos os parâmetros de entrada do Form para
      uCore.

      Todas as entradas de conponentes gráficos devem ser declarados no record
      RParametrosEntrada que se econtra no ucore.pas.

      E passadas diretamente para a Função Executar, onde a mesma fará o
      relacionamento do parâmetro gráfico com o parâmetro do record.

    }

    procedure AboutApplication(autores: String);
    procedure AtualizarArquivosEntrada(Path: String; focoAutomatico: boolean=false);
    function  ValidarParametrosInformados(ParametrosDeEntrada: TParametrosDeEntrada): Boolean;
    function Executar(): Boolean;
    procedure AtualizarListagemDeArquivos(path: String);
    procedure AtualizarQtdeArquivosMarcados();

    procedure LimparSelecao();
    procedure SelecionarTodos();
    procedure LogarParametrosDeEntrada(ParametrosDeEntrada: TParametrosDeEntrada);


  public
    { Public declarations }

    sPathEntrada             : string;
    objCore                  : TCore;

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnSairClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmMain.btnSobreClick(Sender: TObject);
begin

  AboutApplication('Eduardo C. M. Monteiro');

end;

procedure TfrmMain.LogarParametrosDeEntrada(ParametrosDeEntrada: TParametrosDeEntrada);
var
  iContArquivos : Integer;
begin
  objCore.objLogar.Logar('[DEBUG] ID..............................: ' + ParametrosDeEntrada.ID_PROCESSAMENTO);
  objCore.objLogar.Logar('[DEBUG] ARQUIVOS SELECIONADOS...........: ');

  for iContArquivos := 0 TO ParametrosDeEntrada.LISTADEARQUIVOSDEENTRADA.Count -1 DO
    objCore.objLogar.Logar('[DEBUG] -> ' + ParametrosDeEntrada.LISTADEARQUIVOSDEENTRADA.Strings[iContArquivos]);

  objCore.objLogar.Logar('[DEBUG] INFORMAÇÕES.....................: ' + ParametrosDeEntrada.INFORMACAO_DOS_ARQUIVOS_SELECIONADOS);
  objCore.objLogar.Logar('[DEBUG] PATH ENTRADA....................: ' + ParametrosDeEntrada.PATHENTRADA);
  objCore.objLogar.Logar('[DEBUG] PATH SAIDA......................: ' + ParametrosDeEntrada.PATHSAIDA);
  objCore.objLogar.Logar('[DEBUG] PATH ARQUIVOS TEMPORARIOS.......: ' + ParametrosDeEntrada.PATHARQUIVO_TMP);
  objCore.objLogar.Logar('[DEBUG] TABELA DE PROCESSAMENTO.........: ' + ParametrosDeEntrada.TABELA_PROCESSAMENTO);
  objCore.objLogar.Logar('[DEBUG] TABELA DE PLANO DE TRIAGEM......: ' + ParametrosDeEntrada.TABELA_PLANO_DE_TRIAGEM);
  objCore.objLogar.Logar('[DEBUG] NUMERO DE REGISTROS POR SELECT..: ' + ParametrosDeEntrada.LIMITE_DE_SELECT_POR_INTERACOES_NA_MEMORIA);
end;

function TfrmMain.Executar(): Boolean;
var
  sListaMensagens: string;
  iNumeroDeErros: integer;

begin

  LogarParametrosDeEntrada(objCore.objParametrosDeEntrada);

  if not ValidarParametrosInformados(objCore.objParametrosDeEntrada) then
  begin
    showmessage('[ERRO] Erros ocorreram. Confira o arquivo de Log.');
    exit;
  end
  else
  begin

    btnExecutar.Enabled := False;

    btnExecutar.Enabled := false;
    screen.Cursor       := crSQLWait;

    objCore.MainLoop();

    btnExecutar.Enabled := true;
    screen.Cursor := crDefault;

  end;

end;

function TfrmMain.ValidarParametrosInformados(ParametrosDeEntrada: TParametrosDeEntrada): Boolean;
var
  bValido        : boolean;
  sMSG           : string;

begin

  bValido := true;
   //TODA SUA VALIDADÇÃO AQUI

  if ParametrosDeEntrada.LISTADEARQUIVOSDEENTRADA.Count <= 0  then
  begin
    bValido := False;
    sMSG    := '[ERRO] Nenhum arquivo selecionado. O programa será encerrado agora.'+#13#10#13#10;
    showmessage(sMSG);
    objCore.objLogar.Logar(sMSG);
  end;


  // flag que define se todos os parâmetros estão válidos.
  Result:= bValido;

end;

procedure TfrmMain.btnExecutarClick(Sender: TObject);
var
  ListaDeArquivosSelecionados: TStringList;
  iContArquivosSelecionados: Integer;
  sMSG : string;
begin
  try
    try

      ListaDeArquivosSelecionados:= TStringList.Create();
      for iContArquivosSelecionados:= 0 to cltArquivos.Count - 1 do
        if cltArquivos.Checked[iContArquivosSelecionados] then
          ListaDeArquivosSelecionados.Add(cltArquivos.Items[iContArquivosSelecionados]);

      objCore.objParametrosDeEntrada.ID_Processamento                              := lblIdProcessamentoValor.Caption;
      objCore.objParametrosDeEntrada.PathEntrada                                   := edtPathEntrada.Text;
      objCore.objParametrosDeEntrada.PathSaida                                     := edtPathSaida.Text;
      objCore.objParametrosDeEntrada.ListaDeArquivosDeEntrada                      := ListaDeArquivosSelecionados;

      objCore.objParametrosDeEntrada.INFORMACAO_DOS_ARQUIVOS_SELECIONADOS          := lblInfos.Caption;

      objCore.objParametrosDeEntrada.HORA_INICIO_PROCESSO                          := Now;

      Executar(); //rrParametrosRetorno                                                       := Executar();

      objCore.objParametrosDeEntrada.HORA_FIM_PROCESSO                             := Now;

      LimparSelecao;
      AtualizarArquivosEntrada(edtPathEntrada.Text, true);
      pgcMain.TabIndex := 0;

    finally
      ListaDeArquivosSelecionados.Clear;
      FreeAndNil(ListaDeArquivosSelecionados);

      objCore.objLogar.Logar('[DEBUG] INICIO PROCESSO...: ' + FormatDateTime('DD/MM/YYYY - hh:mm:ss', objCore.objParametrosDeEntrada.HORA_INICIO_PROCESSO));
      objCore.objLogar.Logar('[DEBUG] FIM PROCESSO......: ' + FormatDateTime('DD/MM/YYYY - hh:mm:ss', objCore.objParametrosDeEntrada.HORA_FIM_PROCESSO));
      objCore.objLogar.Logar('[DEBUG] DURACAO PROCESSO..: ' + FormatDateTime('hh:mm:ss', objCore.objParametrosDeEntrada.HORA_FIM_PROCESSO -
                                                                                         objCore.objParametrosDeEntrada.HORA_INICIO_PROCESSO));

    end;

    ShowMessage('FIM DE PROCESSAMENTO');

  except
    on E:Exception do
    begin
      sMSG := '[ERRO] Erro ao execultar a Função Executar(). '+#13#10#13#10
             +'EXCEÇÃO: '+ E.Message + #13#10#13#10
             +'O programa será encerrado agora.';

      showmessage(sMSG);
      objCore.objLogar.Logar(sMSG);

      Application.Terminate;
    end;
  end;

end;

procedure TfrmMain.FormShow(Sender: TObject);
begin

  objCore := TCore.Create();

  edtPathEntrada.Text                            := objCore.objParametrosDeEntrada.PATHENTRADA;
  edtPathSaida.Text                              := objCore.objParametrosDeEntrada.PATHSAIDA;
  lblIdProcessamentoValor.Caption                := objCore.objParametrosDeEntrada.ID_PROCESSAMENTO;
  frmMain.Caption                                := StringReplace(ExtractFileName(Application.ExeName), '.exe', '', [rfReplaceAll, rfIgnoreCase])
                                                    + ' - VERSAO: ' + objCore.objFuncoesWin.GetVersaoDaAplicacao()
                                                    + ' - CONECTADO EM: ' + objCore.objConexao.getHostName();
  pgcMain.TabIndex := 0;
  AtualizarQtdeArquivosMarcados();

end;


procedure TfrmMain.AtualizarArquivosEntrada(path: String; focoAutomatico: boolean=false);
var
  sltListaDeArquivos: TStringList;
begin
  try
    try
      sltListaDeArquivos:= TStringList.Create();
      if Path <> '' then
      begin
        sPathEntrada:=  objCore.objString.AjustaPath(Path);
        //objCore.objFuncoesWin.ObterListaDeArquivosDeUmDiretorio(Path, sltListaDeArquivos);
        objCore.objFuncoesWin.ObterListaDeArquivosDeUmDiretorioV2(Path, sltListaDeArquivos);
      end;
      cltArquivos.Items:= sltListaDeArquivos;
    except
      on E:Exception do
      begin

        showmessage('Não foi possível ler os arquivos no diretório ' + Path + '. '+#13#10#13#10
                   +'EXCEÇÃO: '+E.Message+#13#10#13#10
                   +'O programa será encerrado agora.');
        Application.Terminate;
      end;
    end;
  finally
    FreeAndNil(sltListaDeArquivos);
  end;
end;

procedure TfrmMain.AtualizarListagemDeArquivos(path: String);
var
  rListaDeObjetosDoDiretorio: RInfoArquivo;
  sNomeArquivo: string;
  sTipoItemLista: string;
  i: integer;
begin

  sPathEntrada := path;

  if copy(sPathEntrada, length(sPathEntrada), 1)<>'\' then
    sPathEntrada := sPathEntrada + '\';

  //Limpa a lista de arquivos:
  cltArquivos.Items.Clear;

  rListaDeObjetosDoDiretorio := objCore.objFuncoesWin.GetArquivos('*.*', sPathEntrada);

  for i:=0 to length(rListaDeObjetosDoDiretorio.Nome) - 1 do
  begin

    sNomeArquivo := rListaDeObjetosDoDiretorio.Nome[i];

    sTipoItemLista := objCore.objFuncoesWin.GetItemArquivoOuDiretorio(sPathEntrada+sNomeArquivo);

    if sTipoItemLista = 'arquivo' then
      cltArquivos.Items.Add(sNomeArquivo);
  end;

end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  objCore.objLogar.Logar('TfrmMain.FormDestroy()');
  objCore.objLogar.Logar('');

  if Assigned(objCore) then
    FreeAndNil(objCore);
end;

procedure TfrmMain.btnSelecionarTodosClick(Sender: TObject);
begin
  SelecionarTodos();
end;

procedure TfrmMain.btnLimparSelecaoClick(Sender: TObject);
begin
  LimparSelecao();
end;

procedure TfrmMain.LimparSelecao();
var
  i: integer;
begin
  {Itera pela CheckListBox e marca cada item (checked = true)}

  for i:=0 to cltArquivos.Items.Count-1 do
  begin
    if cltArquivos.Checked[i] then
      cltArquivos.Checked[i] := false;
  end;

  AtualizarQtdeArquivosMarcados();
end;

procedure TfrmMain.SelecionarTodos();
var
  i: integer;
begin
 {Itera pela CheckListBox e marca cada item (checked = true)}

  for i:=0 to cltArquivos.Items.Count-1 do
    cltArquivos.Checked[i] := true;

  AtualizarQtdeArquivosMarcados();

end;

procedure TfrmMain.AtualizarQtdeArquivosMarcados();
var
  j, iTotalMarcados: integer;
  sNomeArquivoAtual: string;
  rrTamanhoArquivos: RFile;
  iTamArquivos:int64;
begin
  iTotalMarcados := 0;
  iTamArquivos := 0;

  {Itera na checklistbox}
  for j:=0 to cltArquivos.Items.Count-1 do
  begin
    if cltArquivos.Checked[j] then
    begin
      iTotalMarcados    := iTotalMarcados + 1;
      sNomeArquivoAtual := sPathEntrada+cltArquivos.Items[j];

      if trim(sNomeArquivoAtual) <> '' then
        iTamArquivos := iTamArquivos + objCore.objFuncoesWin.GetTamanhoArquivo_WinAPI(sNomeArquivoAtual)
      else
        iTamArquivos := iTamArquivos + 0;
    end;
  end;

//  rrTamanhoArquivos := objCore.objFuncoesWin.GetTamanhoMaiorUnidade(iTamArquivos);

//  lblInfos.Caption := inttostr(iTotalMarcados) + ' arquivo(s) marcado(s)  - '
//   +floattostr(rrTamanhoArquivos.Tamanho) + ' ' + rrTamanhoArquivos.Unidade;

  lblInfos.Caption := inttostr(iTotalMarcados) + ' arquivo(s) marcado(s)  - '
   + objCore.objFuncoesWin.GetTamanhoMaiorUnidade(iTamArquivos);

  lblInfos.Refresh;
  Application.ProcessMessages;

end;

procedure TfrmMain.cltArquivosClick(Sender: TObject);
begin
  AtualizarQtdeArquivosMarcados();
end;

procedure TfrmMain.btnSelecionarPathClick(Sender: TObject);
var
  sPath: string;
begin
  sPath := edtPathEntrada.Text;
  SelectDirectory('Path de origem dos arquivos de entrada.', sPath, sPath);
  AtualizarArquivosEntrada(sPath, true);
  edtPathEntrada.Text := sPath;
end;

procedure TfrmMain.edtPathEntradaChange(Sender: TObject);
begin
  LimparSelecao;
  AtualizarArquivosEntrada(edtPathEntrada.Text, true);
end;

procedure TfrmMain.btnSelecionarPathSaidaClick(Sender: TObject);
var
  sPath: string;
begin
  SelectDirectory('Path de origem dos arquivos de entrada.', sPath, sPath);
  edtPathSaida.Text:= sPath;
end;

procedure TfrmMain.AboutApplication(autores: String);
var
  sMensagem: string;
  wDia : Word;
  wMes : Word;
  wAno : Word;
begin
  (*

   CRIADA POR: Eduardo Cordeiro M. Monteiro

  *)

  DecodeDate(Now(), wAno, wMes, wDia);

  sMensagem := Application.Title + #13#10
             + ' Versão '+ objCore.objFuncoesWin.GetVersaoDaAplicacao() + #13#10
             + ' @2010-' + IntToStr(wAno) + ' Fingerprint - ' + autores;

  showmessage(sMensagem);

end;

end.

