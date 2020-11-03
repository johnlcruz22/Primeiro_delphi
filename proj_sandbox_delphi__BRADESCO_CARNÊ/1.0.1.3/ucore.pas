unit ucore;

interface

uses
  Windows, Messages, Variants, Graphics, Controls, FileCtrl,
  Dialogs, StdCtrls,  Classes, SysUtils, Forms,
  DB, ZConnection, ZAbstractRODataset, ZAbstractDataset, ZDataset, ZSqlProcessor,
  ADODb, DBTables,
  udatatypes_apps,
  // Classes
  ClassParametrosDeEntrada,
  ClassArquivoIni, ClassStrings, ClassConexoes, ClassConf, ClassMySqlBases,
  ClassTextFile, ClassDirectory, ClassLog, ClassFuncoesWin, ClassLayoutArquivo,
  ClassBlocaInteligente, ClassFuncoesBancarias, ClassPlanoDeTriagem, ClassExpressaoRegular;

type

  TCore = class(TObject)
  private

    __queryMySQL_processamento__    : TZQuery;
    __queryMySQL_plano_de_triagem__ : TZQuery;

    function validaOperadora(iQuantidadeDeModelos: integer;sOperadora: String): Boolean;
    // FUNÇÃO DE PROCESSAMENTO
    Procedure PROCESSAMENTO();

  public

    __ListaPlanoDeTriagem__       : TRecordPlanoTriagemCorreios;

    objParametrosDeEntrada   : TParametrosDeEntrada;
    objConexao               : TMysqlDatabase;
    objPlanoDeTriagem        : TPlanoDeTriagem;
    objString                : TFormataString;
    objLogar                 : TArquivoDelog;
    objArquivoIni            : TArquivoIni;
    objArquivoDeConexoes     : TArquivoDeConexoes;
    objArquivoDeConfiguracao : TArquivoConf;
    objDiretorio             : TDiretorio;
    objFuncoesWin            : TFuncoesWin;
    objLayoutArquivoCliente  : TLayoutCliente;
    objBlocagemInteligente   : TBlocaInteligente;
    objFuncoesBancarias      : TFuncoesBancarias;
    objExpressaoRegular      : TExpressaoRegular;

    procedure setConexao(var objConexaoBanco: TMysqlDatabase);
    procedure ExcluirBase(NomeTabela: String);
    procedure ExcluirTabela(NomeTabela: String);
    Function  FormataDataVencimento(sVencimento : String) : String;
    Function  RetornaCalculaCase(iRoda : Integer; iTotalCarnes : Integer; iRepeticoes: Integer) : TStringList;
    procedure MainLoop();
    constructor create();

  end;

var
  rrOperadoras : array of Integer;

implementation

uses uMain, Math;

constructor TCore.create();
var
  sMSG                       : string;
  sArquivosScriptSQL         : string;
  stlScripSQL                : TStringList;
begin

  try

    stlScripSQL                          := TStringList.Create();
    objParametrosDeEntrada               := TParametrosDeEntrada.Create();
    objLogar                             := TArquivoDelog.Create();
    objFuncoesWin                        := TFuncoesWin.create(objLogar);
    objString                            := TFormataString.Create(objLogar);
    objLayoutArquivoCliente              := TLayoutCliente.Create();
    objFuncoesBancarias                  := TFuncoesBancarias.Create();
    objExpressaoRegular                  := TExpressaoRegular.Create();

    objArquivoIni                        := TArquivoIni.create(objLogar,
                                                               objString,
                                                               ExtractFilePath(Application.ExeName),
                                                               ExtractFileName(Application.ExeName));

    objArquivoDeConexoes                 := TArquivoDeConexoes.create(objLogar,
                                                                      objString,
                                                                      objArquivoIni.getPathConexoes());

    objArquivoDeConfiguracao             := TArquivoConf.create(objArquivoIni.getPathConfiguracoes(),
                                                                ExtractFileName(Application.ExeName));

    objParametrosDeEntrada.ID_PROCESSAMENTO := objArquivoDeConfiguracao.getIDProcessamento;

    objConexao                           := TMysqlDatabase.Create();

    if objArquivoIni.getPathConfiguracoes() <> '' then
    begin

      objParametrosDeEntrada.PATHENTRADA := objArquivoDeConfiguracao.getConfiguracao(
       'path_default_arquivos_entrada');

      objParametrosDeEntrada.PATHSAIDA := objArquivoDeConfiguracao.getConfiguracao(
       'path_default_arquivos_saida');

      objParametrosDeEntrada.TABELA_PROCESSAMENTO := objArquivoDeConfiguracao.getConfiguracao(
       'tabela_processamento');

      objParametrosDeEntrada.TABELA_PLANO_DE_TRIAGEM := objArquivoDeConfiguracao.getConfiguracao(
       'tabela_plano_de_triagem');

      objParametrosDeEntrada.CARREGAR_PLANO_DE_TRIAGEM_MEMORIA := objArquivoDeConfiguracao.getConfiguracao(
       'CARREGAR_PLANO_DE_TRIAGEM_MEMORIA');

      objParametrosDeEntrada.TABELA_BLOCAGEM_INTELIGENTE := objArquivoDeConfiguracao.getConfiguracao(
       'TABELA_BLOCAGEM_INTELIGENTE');

      objParametrosDeEntrada.TABELA_BLOCAGEM_INTELIGENTE_RELATORIO := objArquivoDeConfiguracao.getConfiguracao(
       'TABELA_BLOCAGEM_INTELIGENTE_RELATORIO');

      objParametrosDeEntrada.LIMITE_DE_SELECT_POR_INTERACOES_NA_MEMORIA := objArquivoDeConfiguracao.getConfiguracao(
       'numero_de_select_por_interacoes_na_memoria');

      objParametrosDeEntrada.NUMERO_DE_IMAGENS_PARA_BLOCAGENS := objArquivoDeConfiguracao.getConfiguracao(
       'NUMERO_DE_IMAGENS_PARA_BLOCAGENS');

      objParametrosDeEntrada.BLOCAR_ARQUIVO := objArquivoDeConfiguracao.getConfiguracao(
       'BLOCAR_ARQUIVO');

      objParametrosDeEntrada.BLOCAGEM := objArquivoDeConfiguracao.getConfiguracao(
       'BLOCAGEM');

      objParametrosDeEntrada.MANTER_ARQUIVO_ORIGINAL := objArquivoDeConfiguracao.getConfiguracao(
       'MANTER_ARQUIVO_ORIGINAL');

      objLogar.Logar('[DEBUG] TfrmMain.FormCreate() - Versão do programa: ' + objFuncoesWin.GetVersaoDaAplicacao());

      objParametrosDeEntrada.PathArquivo_TMP := objArquivoIni.getPathArquivosTemporarios();

      // Criando a Conexao
      objConexao.ConectarAoBanco( objArquivoDeConexoes.getHostName,
                                  'mysql',
                                  objArquivoDeConexoes.getUser,
                                  objArquivoDeConexoes.getPassword,
                                  objArquivoDeConexoes.getProtocolo
                                  );

      sArquivosScriptSQL := ExtractFileName(Application.ExeName);
      sArquivosScriptSQL := StringReplace(sArquivosScriptSQL, '.exe', '.sql', [rfReplaceAll, rfIgnoreCase]);
      stlScripSQL.LoadFromFile(objArquivoIni.getPathScripSQL() + sArquivosScriptSQL);
      objConexao.ExecutaScript(stlScripSQL);

      objBlocagemInteligente   := TBlocaInteligente.create(objParametrosDeEntrada,
                                                           objConexao,
                                                           objFuncoesWin,
                                                           objString,
                                                           objLogar);

      // Criando Objeto de Plano de Triagem
      if StrToBool(objParametrosDeEntrada.CARREGAR_PLANO_DE_TRIAGEM_MEMORIA) then
        objPlanoDeTriagem := TPlanoDeTriagem.create(objConexao,
                                                    objLogar,
                                                    objString,
                                                    objParametrosDeEntrada.TABELA_PLANO_DE_TRIAGEM, fac);

    end;

  except
    on E:Exception do
    begin

      sMSG := '[ERRO] Não foi possível inicializar as configurações do programa. '+#13#10#13#10
            + ' EXCEÇÃO: '+E.Message+#13#10#13#10
            + ' O programa será encerrado agora.';

      showmessage(sMSG);

      objLogar.Logar(sMSG);

      Application.Terminate;
    end;
  end;

end;

procedure TCore.setConexao(var objConexaoBanco: TMysqlDatabase);
begin
  objConexao := objConexaoBanco;
end;

procedure TCore.MainLoop();
var
  sMSG : string;

  sPathEntrada : string;
  sPathSaida : string;
begin

  objLogar.Logar('[DEBUG] TCore.MainLoop() - begin...');
  try
    try

      if objParametrosDeEntrada.PathEntrada = '' then
        sPathEntrada := '.\';

      if objParametrosDeEntrada.PathSaida = '' then
        sPathSaida := '.\';

      objDiretorio := TDiretorio.create(objParametrosDeEntrada.PathEntrada);
      objParametrosDeEntrada.PathEntrada := objDiretorio.getDiretorio();

      objDiretorio.setDiretorio(objParametrosDeEntrada.PathSaida);
      objParametrosDeEntrada.PathSaida   := objDiretorio.getDiretorio();



      PROCESSAMENTO();

    finally

      if Assigned(objDiretorio) then
      begin
        objDiretorio.destroy;
        Pointer(objDiretorio) := nil;
      end;

    end;

  except
    on E:Exception do
    begin
      sMSG :='Erro ao execultar a Função MainLoop(). '+#13#10#13#10
                 +'EXCEÇÃO: '+E.Message+#13#10#13#10
                 +'O programa será encerrado agora.';

      showmessage(sMSG);
      objLogar.Logar(sMSG);
    end;
  end;

  objLogar.Logar('[DEBUG] TCore.MainLoop() - ...end');

end;


function tCore.validaOperadora(iQuantidadeDeModelos: integer;sOperadora: String): Boolean;
var
  i : Integer;
  iTotalEncontrados : Integer;
begin

  if rrOperadoras[StrToInt(sOperadora)] >= iQuantidadeDeModelos then
    Result := False
  else
    Result := True;

end;

Procedure TCore.PROCESSAMENTO();
Var

objArquivoSaida    : TArquivoTexto;
objArquivoRelat    : TArquivoTexto;
Arq_Arquivo_Entada : TextFile;

iContArquivos    : Integer;
iTotalDeArquivos : Integer;
iAcumulaQuantiCar: Integer;

sArquivoEntrada : string;
sArquivoSaida   : string;
sArquivoRela    : string;
sComando        : string;
sCampos         : string;
sLinha          : string;
sCPF_CNPJ       : string;
sLinhaTipo3     : string;
sLinhaTEMP      : string;
sTipo           : string;
sValor          : string;
scampoLivre     : string;
sIdDaEmpresa    : string;
sControle       : string;
sControAntes    : string;
sValues         : string;
sDataVencimento : string;
sCabecalho      : string;
sLaminaAtual    : string;
stotalAtual     : string;
sLinhaFalsa     : string;
sSEQUENCIATABE  : string;
sLaminaAnterior : string;
sCPFatual       : string;
sCPFanterior    : string;
sQuantidadePC   : String;

// Variáveis de controle do select
iTotalDeRegistrosDaTabela   : Integer;
iLimit                      : Integer;
iTotalDeInteracoesDeSelects : Integer;
iResto                      : Integer;
iRegInicial                 : Integer;
iQtdeRegistros              : Integer;
iContInteracoesDeSelects    : Integer;
iTotalCarne                 : Integer;
iContaLamina                : Integer;
iForLaminas                 : Integer;
iForSelect                  : Integer;
iForGeraSemBranco           : Integer;
iControlaLimite             : Integer;
iLaminasNaTabela            : Integer;
iTotalParcelas              : Integer;
iContaLaminaequali          : Integer;
iContsaida                  : Integer;
iNumeraSaida                : Integer;

bNaoContaPrimeiro           : Boolean;

tGuardaLaminas   : TStringList;
tCompletatipo1e2 : TStringList;
tLaminasNaTabela : TStringList;
tNumerosSelect   : TStringList;

sCep       : string;

flEntrada  : TextFile;
i          : Integer;
controlefor: Integer;
j          : Integer;
ifantasma  : Integer;
teste      : Integer;

begin

  if not DirectoryExists(objParametrosDeEntrada.PathSaida) then
    ForceDirectories(objParametrosDeEntrada.PathSaida);

  //*********************************************************************************************
  //                         Alimentando nome dos campos da tabela de Cliente
  //*********************************************************************************************
  sComando := 'describe ' + objParametrosDeEntrada.tabela_processamento;
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);


  while not __queryMySQL_processamento__.Eof do
  Begin
    sCampos := sCampos + __queryMySQL_processamento__.FieldByName('Field').AsString;
    __queryMySQL_processamento__.Next;
    if not __queryMySQL_processamento__.Eof then
      sCampos := sCampos + ',';
  end;

  iAcumulaQuantiCar:=0;
  iTotalDeArquivos := objParametrosDeEntrada.ListaDeArquivosDeEntrada.Count;

  sArquivoSaida   := 'DOC_BRADESCO.TXT';
  sArquivoRela    := 'RELATORIO.TXT';

  if not DirectoryExists(objParametrosDeEntrada.PATHSAIDA + 'DOC_TEMP') then
         forceDirectories(objParametrosDeEntrada.PATHSAIDA + 'DOC_TEMP');

   objArquivoSaida := TArquivoTexto.Create(objDiretorio, objParametrosDeEntrada.PathSaida+ '\DOC_TEMP\' + sArquivoSaida , criacao);

  if not DirectoryExists(objParametrosDeEntrada.PATHSAIDA + 'REL') then
         forceDirectories(objParametrosDeEntrada.PATHSAIDA + 'REL');

   objArquivoRelat := TArquivoTexto.Create(objDiretorio, objParametrosDeEntrada.PathSaida+ '\REL\' + sArquivoRela , criacao);

  objArquivoRelat.EscreverNoArquivo('*****************************************************************');
  objArquivoRelat.EscreverNoArquivo('                 RELATORIO DE QUANTIDADE - CARNES BRADESCO');
  objArquivoRelat.EscreverNoArquivo('*****************************************************************');
  objArquivoRelat.EscreverNoArquivo('*****************************************************************');
  objArquivoRelat.EscreverNoArquivo(' ');
  objArquivoRelat.EscreverNoArquivo('QUANTIDADE DE CARNES');

  for iContArquivos := 0 to iTotalDeArquivos - 1 do
  begin

    sComando := 'delete from ' + objParametrosDeEntrada.tabela_processamento;
    objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

    sArquivoEntrada := objParametrosDeEntrada.ListaDeArquivosDeEntrada.Strings[iContArquivos];

    AssignFile(flEntrada, objParametrosDeEntrada.PathEntrada + sArquivoEntrada);
    reset(flEntrada);

    bNaoContaPrimeiro := true;
    iContaLamina      := 0;
    iTotalCarne       := 0;
    sControle         := '0000';
    sControAntes      := '0000';

    tGuardaLaminas    := TStringList.Create;

  while not eof(flEntrada) do
    Begin

      readln(flEntrada, sLinha);

      sLinha       := StringReplace(sLinha, '"', ' ', [rfReplaceAll, rfIgnoreCase]);
      sTipo        := Copy(sLinha,0,1);
      sIdDaEmpresa := Copy(sLinha,21,17);

     if (sTipo = '0') then
      begin
       sCabecalho := sLinha;
      end;

     if (sTipo = '2') then
      begin
        scampoLivre := Copy(sLinha,371,4)+Copy(sLinha,368,2)+Copy(sLinha,383,11)+Copy(sLinha,375,7)+'0'; //CAMPO LIVRE
        sLinhaTipo3 := objFuncoesBancarias.BRADESCO_SR_CODIGOBARRAS('237','9',sDataVencimento,sValor,scampoLivre) + '   ' + objFuncoesBancarias.BRADESCO_SR_LINHADIGITAVEL('237','9',sDataVencimento,sValor,scampoLivre) + '    ' + sDataVencimento + '    ' + FormatDateTime('DD/MM/YYYY', Now) + '    ' + scampoLivre;
        tGuardaLaminas.Add(objString.AjustaStr(sLinhaTEMP,401) +'    '+ Copy(sLinha,1,401) +'    ' + sLinhaTipo3);
      end
     else
     if (sTipo = '1') then
      begin
        sControle      := Copy(sLinha,44,22);
        sCep           := Copy(sLinha,327,8);
        sCPF_CNPJ      := Copy(sLinha,224,11);
        sValor         := Copy(sLinha,130,10);
        sDataVencimento:= FormataDataVencimento(Copy(sLinha,121,6));
        sLinhaTEMP     := Copy(sLinha,1,401);
        //tGuardaLaminas.Add(Copy(sLinha,1,401));
      end;

      // CONTA QUANTIDADE DE LAMINAS
      if (sTipo = '1') and (sControle <> sControAntes) and (sControAntes<> '0000') or (sTipo = '9') then
      begin

        iTotalCarne := iTotalCarne + 1;

       if (sTipo <> '9') then
       begin

        for i := 0 to tGuardaLaminas.Count-1 do
         begin

          sValues :=  '"' + FormatFloat('000',iContaLamina)       + '",'
                    + '"' + FormatFloat('000',i+1)+ '/'             + FormatFloat('000',iContaLamina)       + '",'
                    + '"' + sCep                                  + '",'
                    + '"' + sCPF_CNPJ                             + '",'
                    + '"' + tGuardaLaminas.Strings[i]             + '",'
                    + '"' + FormatFloat('0000000',i+1)            + '"';

          sComando := 'Insert into ' + objParametrosDeEntrada.tabela_processamento + ' (' + sCampos + ') values(' + sValues + ')';
          objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

         end;

        iContaLamina   :=0;
        tGuardaLaminas.Free;
        tGuardaLaminas := nil;
        tGuardaLaminas := TStringList.Create;
        sLinhaTEMP     := Copy(sLinha,1,401);
//        tGuardaLaminas.Add(Copy(sLinha,1,401));
       end
       else
        begin
        for i := 0 to tGuardaLaminas.Count-1 do
         begin

          sValues :=   '"' + FormatFloat('000',iContaLamina)       + '",'
                     + '"' + FormatFloat('000',i+1)+ '/'           + FormatFloat('000',iContaLamina)       + '",'
                     + '"' + sCep                                  + '",'
                     + '"' + sCPF_CNPJ                             + '",'
                     + '"' + tGuardaLaminas.Strings[i]             + '",'
                     + '"' + FormatFloat('0000000',i+1)            + '"';

          sComando := 'Insert into ' + objParametrosDeEntrada.tabela_processamento + ' (' + sCampos + ') values(' + sValues + ')';
          objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

         end;

        iContaLamina   :=0;
        tGuardaLaminas.Free;
        tGuardaLaminas := nil;
        tGuardaLaminas := TStringList.Create;
        sLinhaTEMP     := Copy(sLinha,1,401);
//        tGuardaLaminas.Add(Copy(sLinha,1,401));

        end;

      end
      else
      if (sTipo = '2') and (sControle = sControAntes) then
      begin
        iContaLamina := iContaLamina + 1;
      end;
      // ATÉ AQUI CONTROLA A CONTAGEM DE LAMINA

       sControAntes := sControle;

      if (sTipo = '0') then
      begin
        bNaoContaPrimeiro := false;
      end;


    end;

    CloseFile(flEntrada);
  end;
  tCompletatipo1e2.Free;
  tCompletatipo1e2 := nil;


    sComando := 'SELECT count(LINHA) as qtde FROM ' + objParametrosDeEntrada.tabela_processamento;
    objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

    iTotalDeRegistrosDaTabela := __queryMySQL_processamento__.FieldByName('qtde').AsInteger;

    iLimit := StrToInt(objParametrosDeEntrada.LIMITE_DE_SELECT_POR_INTERACOES_NA_MEMORIA);
    iResto := iTotalDeRegistrosDaTabela mod iLimit;


    if iResto <> 0 then
      iTotalDeInteracoesDeSelects := iTotalDeRegistrosDaTabela div iLimit + 1
    else
      iTotalDeInteracoesDeSelects := iTotalDeRegistrosDaTabela div iLimit;

    iQtdeRegistros := 0;
    iNumeraSaida   := 1;

   sComando := 'SELECT * FROM ' + objParametrosDeEntrada.tabela_processamento + ' group by laminas order by laminas desc ;';
   objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

   tLaminasNaTabela := TStringList.Create;

    while not __queryMySQL_processamento__.Eof do
      begin
       tLaminasNaTabela.Add(__queryMySQL_processamento__.FieldByName('LAMINAS').AsString);

       __queryMySQL_processamento__.Next;
      end;

  iTotalParcelas  := 0;
  iLaminasNaTabela:= 0;
  iTotalCarne     := 0;

  sLinhaFalsa := '1                   00000000000000000000000      00000           0000000000000000000000000000N              000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000              '+
                 '                                                                              00000000                                                            000000     20000                                                                                      '+
                 '                                                                                                                                                                                                                                                        '+
                 '                           0000000000000000000000000000000000    00000000000000000000000000000000000000000000   000000000000000000000000 000000000000 0 00000000000000    0000000000    0000000000    0000000000000000000000000000000000 ';

  objArquivoSaida.EscreverNoArquivo(objString.AjustaStr(sCabecalho,976));
  for iContInteracoesDeSelects := 0 to iTotalDeInteracoesDeSelects -1 do
  begin
      iRegInicial    := iQtdeRegistros;
      iQtdeRegistros := iQtdeRegistros + iLimit;

   for  iForLaminas:=0 to tLaminasNaTabela.Count-1 do
   begin

    iLaminasNaTabela := StrToInt(tLaminasNaTabela.Strings[iForLaminas]);

    sComando := 'SELECT count(LAMINAS) as qtde FROM ' + objParametrosDeEntrada.tabela_processamento + ' WHERE LAMINAS ='+ FormatFloat('000',iLaminasNaTabela)+ ' AND PARCELA="001/'+ FormatFloat('000',iLaminasNaTabela)+'"';
    objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

    sQuantidadePC := __queryMySQL_processamento__.FieldByName('qtde').AsString;

    iAcumulaQuantiCar := iAcumulaQuantiCar + StrToInt(sQuantidadePC);

    objArquivoRelat.EscreverNoArquivo(tLaminasNaTabela.Strings[iForLaminas] + ' PARCELAS.....: '+sQuantidadePC +' CARNE(S)' );

    sComando := 'SELECT count(LAMINAS) as qtde FROM ' + objParametrosDeEntrada.tabela_processamento + ' WHERE LAMINAS ='+ IntToStr(iLaminasNaTabela);
    objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

    while not __queryMySQL_processamento__.Eof do
     begin

      iTotalParcelas := __queryMySQL_processamento__.FieldByName('qtde').AsInteger;
     __queryMySQL_processamento__.Next;

     end;

     iTotalCarne        := iTotalParcelas div iLaminasNaTabela;
     iContaLaminaequali := 3 -(iTotalCarne mod 3);

      Case (iContaLaminaequali) of
       1 :
       begin

        for iForSelect := 0 to iLaminasNaTabela-1 do
        begin
          sComando := 'SELECT * FROM ' + objParametrosDeEntrada.tabela_processamento +
          ' where laminas ='+ IntToStr(iLaminasNaTabela) +' order by PARCELA desc, laminas desc, cep desc limit ' +   IntToStr(iForSelect*2) +',2';

          objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

          iControlaLimite := 0;


        while not __queryMySQL_processamento__.Eof do
          begin
           sLinha        := __queryMySQL_processamento__.FieldByName('LINHA').AsString;
           sLaminaAtual  := __queryMySQL_processamento__.FieldByName('PARCELA').AsString;
           stotalAtual   := __queryMySQL_processamento__.FieldByName('LAMINAS').AsString;
           sSEQUENCIATABE:= __queryMySQL_processamento__.FieldByName('SEQUENCIA').AsString;

           if (iControlaLimite = 0) then
           begin
            objArquivoSaida.EscreverNoArquivo(sLinhaFalsa + sLaminaAtual + ' '+ sSEQUENCIATABE + ' ' + FormatFloat('0000000',iNumeraSaida));
           end;
            objArquivoSaida.EscreverNoArquivo(objString.AjustaStr(sLinha,976) + ' ' + sLaminaAtual + ' '+ sSEQUENCIATABE+ ' ' + FormatFloat('0000000',iNumeraSaida));

            iControlaLimite := iControlaLimite + 1;

           __queryMySQL_processamento__.Next;

          end;

          iNumeraSaida := iNumeraSaida + 1;
        end;

       end;

       2 :
       begin
        sComando := 'SELECT * FROM ' + objParametrosDeEntrada.tabela_processamento + ' where laminas =' + IntToStr(iLaminasNaTabela) + ' order by PARCELA DESC';
        objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

        while not __queryMySQL_processamento__.Eof do
         begin
          sLinha        := __queryMySQL_processamento__.FieldByName('LINHA').AsString;
          sLaminaAtual  := __queryMySQL_processamento__.FieldByName('PARCELA').AsString;
          stotalAtual   := __queryMySQL_processamento__.FieldByName('LAMINAS').AsString;
          sSEQUENCIATABE:= __queryMySQL_processamento__.FieldByName('SEQUENCIA').AsString;


          objArquivoSaida.EscreverNoArquivo(sLinhaFalsa + sLaminaAtual + ' '+ sSEQUENCIATABE + ' ' + FormatFloat('0000000',iNumeraSaida));
          objArquivoSaida.EscreverNoArquivo(sLinhaFalsa + sLaminaAtual + ' '+ sSEQUENCIATABE + ' ' + FormatFloat('0000000',iNumeraSaida));
          objArquivoSaida.EscreverNoArquivo(objString.AjustaStr(sLinha,976) + ' ' + sLaminaAtual + ' '+ sSEQUENCIATABE + ' ' + FormatFloat('0000000',iNumeraSaida));

          __queryMySQL_processamento__.Next;
          iNumeraSaida := iNumeraSaida + 1;

         end;



       end;
      else
       begin

        tNumerosSelect := TStringList.Create;

        for iForGeraSemBranco := 1 to (iTotalCarne div 3) do
        begin
//            iControlaLimite := iTotalCarne*iForGeraSemBranco;

          tNumerosSelect := RetornaCalculaCase(iForGeraSemBranco, iTotalCarne, iLaminasNaTabela);
          
          for iForSelect := 0 to iLaminasNaTabela-1 do
          begin




            sComando := 'SELECT * FROM ' + objParametrosDeEntrada.tabela_processamento +
            ' where laminas ='+ IntToStr(iLaminasNaTabela) +' order by PARCELA desc, laminas desc, cep desc limit ' +  tNumerosSelect.Strings[iForSelect]  + ',3';
            objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

           while not __queryMySQL_processamento__.Eof do
            begin
             sLinha        := __queryMySQL_processamento__.FieldByName('LINHA').AsString;
             sLaminaAtual  := __queryMySQL_processamento__.FieldByName('PARCELA').AsString;
             stotalAtual   := __queryMySQL_processamento__.FieldByName('LAMINAS').AsString;
             sSEQUENCIATABE:= __queryMySQL_processamento__.FieldByName('SEQUENCIA').AsString;

              objArquivoSaida.EscreverNoArquivo(objString.AjustaStr(sLinha,976) + ' ' + sLaminaAtual + ' '+ sSEQUENCIATABE + ' ' + FormatFloat('0000000',iNumeraSaida));

             __queryMySQL_processamento__.Next;

            end;

            iNumeraSaida := iNumeraSaida + 1;

          end;

        end;

       end;

      end;



   end;

  end;
  objArquivoRelat.EscreverNoArquivo(' ');
  objArquivoRelat.EscreverNoArquivo(' ');
  objArquivoRelat.EscreverNoArquivo('TOTAL DE CARNES..: '+ FormatFloat('00000',iAcumulaQuantiCar));
  objArquivoRelat.EscreverNoArquivo(' ');
  objArquivoRelat.EscreverNoArquivo('*****************************************************************');  
  objArquivoRelat.EscreverNoArquivo('QUANTIDADE DE LAMINAS POR PARCELAS');
  objArquivoRelat.EscreverNoArquivo('*****************************************************************');
  objArquivoRelat.EscreverNoArquivo(' ');

 for iForSelect := 0 to tLaminasNaTabela.Count-1 do
  begin

   iLaminasNaTabela := StrToInt(tLaminasNaTabela.Strings[iForSelect]);

   sComando := 'SELECT count(LAMINAS) as qtde FROM ' + objParametrosDeEntrada.tabela_processamento + ' WHERE LAMINAS ='+ FormatFloat('000',iLaminasNaTabela);
   objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

   sQuantidadePC := __queryMySQL_processamento__.FieldByName('qtde').AsString;

   objArquivoRelat.EscreverNoArquivo(tLaminasNaTabela.Strings[iForSelect] + ' PARCELAS.....: '+sQuantidadePC +' LAMINA(S)');
  end;

  sComando := 'SELECT DISTINCT count(LAMINAS) as qtde FROM ' + objParametrosDeEntrada.tabela_processamento;
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

  objArquivoRelat.EscreverNoArquivo(' ');
  objArquivoRelat.EscreverNoArquivo(' ');
  objArquivoRelat.EscreverNoArquivo('TOTAL DE LAMINAS.: '+ FormatFloat('00000',__queryMySQL_processamento__.FieldByName('qtde').AsInteger));


  objArquivoSaida.EscreverNoArquivo(objString.AjustaStr('9',575));
  objArquivoSaida.FecharArquivo;
  objArquivoRelat.FecharArquivo;
  tLaminasNaTabela.Free;
  tLaminasNaTabela := nil;



end;


Function TCore.FormataDataVencimento(sVencimento : String) : String;
var
sFormatado: String;
begin
sFormatado := Copy(sVencimento,0,2)+'/'+Copy(sVencimento,3,2)+'/20'+Copy(sVencimento,5,2);

Result := sFormatado;

end;

Function TCore.RetornaCalculaCase(iRoda : Integer; iTotalCarnes : Integer; iRepeticoes: Integer) : TStringList;
var
Tretorno : TStringList;
IFOR     : Integer;
iStart   : Integer;
begin
iStart   :=0;
Tretorno := TStringList.Create;
Tretorno.Clear;

  Case (iRoda) of
     1 : iStart := 0;
     2 : iStart := 3;
     3 : iStart := 6;
     4 : iStart := 9;
     5 : iStart := 12;
     6 : iStart := 15;
     7 : iStart := 18;
     8 : iStart := 21;
     9 : iStart := 24;
  end;

 for IFOR := 0 to iRepeticoes-1 do
 begin
  Tretorno.Add(IntToStr(iStart));
  iStart := iStart + ((iTotalCarnes div 3)*3);
 end;

 Result := Tretorno;

end;



procedure TCore.ExcluirBase(NomeTabela: String);
var
  sComando : String;
  sBase    : string;
begin

  sBase := objString.getTermo(1, '.', NomeTabela);

  sComando := 'drop database ' + sBase;
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);
end;

procedure TCore.ExcluirTabela(NomeTabela: String);
var
  sComando : String;
  sTabela  : String;
begin

  sTabela := objString.getTermo(2, '.', NomeTabela);

  sComando := 'drop table ' + sTabela;
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);
end;

end.
