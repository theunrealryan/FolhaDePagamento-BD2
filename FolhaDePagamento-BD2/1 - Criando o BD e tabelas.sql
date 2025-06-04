-- Criar o banco
CREATE DATABASE FOLHA_PAGTO_DEMO    -- crie se ainda não existir

USE folha_pagto_demo;                -- seleciona o BD

/* -----------------------------------------------------------
   1.  TABELAS BASE
----------------------------------------------------------- */
CREATE TABLE FUNCIONARIOS(           -- dados do colaborador
  MATRICULA    VARCHAR(4)  PRIMARY KEY,
  CPF          VARCHAR(15) NOT NULL,
  NOME         VARCHAR(40) NOT NULL,
  LOCAL_NASC   VARCHAR(20) NOT NULL,
  ESCOLARIDADE CHAR(1)     NOT NULL, -- S,G,E,M,D
  CARGO        INT         NOT NULL,
  ADMISAO      DATE        NOT NULL,
  NASCIMENTO   DATE        NOT NULL,
  DEPENDENTES  INT         NOT NULL,
  VALE_TRANSP  CHAR(1)     NOT NULL, -- S/N
  PLANO_SAUDE  CHAR(1)     NOT NULL  -- S/N
);

CREATE TABLE CARGOS(                 -- cargo + salário base
  CARGO     INT PRIMARY KEY,
  NOMECARGO VARCHAR(40) NOT NULL,
  SALARIO   DECIMAL(10,2) NOT NULL
);

INSERT INTO CARGOS (CARGO, NOMECARGO,SALARIO) VALUES
(1, 'AUXILIAR ADMINISTRATIVO', 954),
(2, 'TECNICO ADMINISTRATIVO', 1200),
(3, 'GESTAO.AUXILIAR', 2000),
(4, 'PROF.AUXILIAR', 3000),
(5, 'PROF.ASSISTENTE', 6000),
(6, 'PROF.ADJUNTO', 10000)


/* -----------------------------------------------------------
   2.  TABELAS AUXILIARES (nenhum valor fixo nas SPs)
----------------------------------------------------------- */

-- 2.1  Faixas do INSS  (ajuste limite <= 7 087,22)
CREATE TABLE INSS_FAIXAS(
  id         INT IDENTITY(1,1) PRIMARY KEY,
  faixa_ini  DECIMAL(10,2),
  faixa_fim  DECIMAL(10,2),
  aliquota   DECIMAL(5,2),  -- %
  valor_fixo DECIMAL(10,2)  -- só teto
);

INSERT INTO INSS_FAIXAS(faixa_ini,faixa_fim,aliquota,valor_fixo) VALUES
(0.00   ,1518.00 , 7.50, 0.00),      -- 1ª faixa
(1518.01,2427.35 , 9.00, 0.00),      -- 2ª faixa
(2427.36,3641.03 ,12.00, 0.00),      -- 3ª faixa
(3641.04,7087.21 ,14.00, 0.00),      -- 4ª faixa termina em 7 087,21
(7087.22,9999999 , 0.00,992.21);     -- ≥ 7 087,22 paga teto

-- 2.2  Faixas do IRRF
CREATE TABLE IRRF_FAIXAS(
  id            INT IDENTITY(1,1) PRIMARY KEY,
  base_ini      DECIMAL(10,2),
  base_fim      DECIMAL(10,2),
  aliquota      DECIMAL(5,2),
  parcela_deduz DECIMAL(10,2)
);

INSERT INTO IRRF_FAIXAS(base_ini,base_fim,aliquota,parcela_deduz) VALUES
(0.00  ,1903.98, 0.00,   0.00),
(1903.99,2826.65,7.50, 142.80),
(2826.66,3751.06,15.00,354.80),
(3751.07,4664.68,22.50,636.13),
(4664.69,9999999,27.50,869.36);

-- 2.3  Percentual por escolaridade
CREATE TABLE ESCOLARIDADE_PERC(
  nivel CHAR(1) PRIMARY KEY, 
  perc DECIMAL(5,2)
);
INSERT INTO ESCOLARIDADE_PERC VALUES
('S',0.00),('G',18.00),('E',25.00),('M',54.00),('D',104.00);

-- 2.4  Parâmetros fixos (usados em cálculos)
CREATE TABLE PARAMETROS_FIXOS(
  chave VARCHAR(30) PRIMARY KEY, 
  valor DECIMAL(10,2)
);
INSERT INTO PARAMETROS_FIXOS VALUES
('FGTS',8.00),
('REPOUSO_PERC',1.00),
('VALE_CULTURA',80.00),
('AUX_ALIMENTACAO',750.00),
('ANUENIO_VALOR',125.00),
('SAL_FAM_SALARIO_LIM',1655.98),
('SAL_FAM_VAL_DEP',56.47),
('VALE_TRANS_PERC',6.00),
('DEDUCAO_DEPENDENTE',189.59),
('PSAUDE_PERC_FUNC',3.75),
('PSAUDE_PERC_DEP',1.15);

-- 2.5  Log de inserção de funcionário (o trigger usa)
CREATE TABLE LOG_INSERCAO_FUNCIONARIO(
  id_log    BIGINT IDENTITY(1,1) PRIMARY KEY,
  data_hora DATETIME NOT NULL,
  matricula VARCHAR(4),
  nome      VARCHAR(40)
);