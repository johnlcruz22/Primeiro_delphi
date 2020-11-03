CREATE DATABASE IF NOT EXISTS BRADESCO_CARNE;

DROP TABLE IF EXISTS BRADESCO_CARNE.processamento;
CREATE TABLE IF NOT EXISTS BRADESCO_CARNE.processamento (
  LAMINAS  varchar(03) default NULL,
  PARCELA  varchar(07) default NULL,
  CEP varchar(10) default NULL,
  CPFCNPJ varchar(11) default NULL,
  LINHA TEXT,
  SEQUENCIA varchar(7) default NULL
);

DROP TABLE IF EXISTS BRADESCO_CARNE.tbl_blocagem;

CREATE TABLE IF NOT EXISTS BRADESCO_CARNE.tbl_blocagem(
  linha VARCHAR(5000),
  diconix integer,
  numeroDaImagem integer,
  lote integer,
  sequencia integer
) CHARACTER SET latin1 COLLATE latin1_swedish_ci;

CREATE INDEX idx_blocagem ON BRADESCO_CARNE.tbl_blocagem (Diconix, numeroDaImagem, lote, sequencia);

CREATE TABLE IF NOT EXISTS BRADESCO_CARNE.tbl_blocagemRelatorio(
  id BIGINT AUTO_INCREMENT,
  data VARCHAR(10),
  duracao VARCHAR(50),
  arquivo VARCHAR(600),
  tamanhoArquivo VARCHAR(50),
  qtdeImagensNoArquivo BIGINT,
  parQtdeImagensBlocagem BIGINT, 
  parBlocagem BIGINT, 
  saidaQtdeLotesComBlocagemPadrao BIGINT,
  saidaSobra BIGINT, 
  saidaBlocagemParaSobra BIGINT, 
  saidaQtdeImagensDesperdicadas BIGINT,
  PRIMARY KEY(id)
) CHARACTER SET latin1 COLLATE latin1_swedish_ci;