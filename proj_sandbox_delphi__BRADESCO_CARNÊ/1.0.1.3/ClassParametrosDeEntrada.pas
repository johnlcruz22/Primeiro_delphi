Unit ClassParametrosDeEntrada;

interface

  uses Classes, Dialogs, SysUtils, Forms, Controls, Graphics,
  StdCtrls, ComCtrls;

  type
    TParametrosDeEntrada= Class
      // Propriedades da Classe ClassParametrosDeEntrada
    HORA_INICIO_PROCESSO                       : TDateTime;
    HORA_FIM_PROCESSO                          : TDateTime;
    INFORMACAO_DOS_ARQUIVOS_SELECIONADOS       : string;

    ID_PROCESSAMENTO                           : STRING;
    LISTADEARQUIVOSDEENTRADA                   : TSTRINGS;
    PATHENTRADA                                : STRING;
    PATHSAIDA                                  : STRING;
    PATHARQUIVO_TMP                            : STRING;

    TABELA_PROCESSAMENTO                       : STRING;
    TABELA_PLANO_DE_TRIAGEM                    : STRING;
    CARREGAR_PLANO_DE_TRIAGEM_MEMORIA          : STRING;
    TABELA_BLOCAGEM_INTELIGENTE                : STRING;
    TABELA_BLOCAGEM_INTELIGENTE_RELATORIO      : STRING;

    NUMERO_DE_IMAGENS_PARA_BLOCAGENS           : STRING;
    BLOCAGEM                                   : STRING;
    BLOCAR_ARQUIVO                             : STRING;
    MANTER_ARQUIVO_ORIGINAL                    : STRING;

    LIMITE_DE_SELECT_POR_INTERACOES_NA_MEMORIA : string;

    end;

implementation


End.
