USE folha_pagto_demo;
GO

/* ---------------------------------------------------------------------
   3.  PROCEDURES DE PROVENTOS E DESCONTOS
--------------------------------------------------------------------- */

-- 3.1  Repouso Remunerado: calcula 1% do salário bruto a partir da tabela PARAMETROS_FIXOS
IF OBJECT_ID('SP_RepousoRemunerado') IS NOT NULL
    DROP PROCEDURE SP_RepousoRemunerado;
GO
CREATE PROCEDURE SP_RepousoRemunerado
  @p_sal DECIMAL(10,2),       -- salário bruto
  @v_val DECIMAL(10,2) OUTPUT -- valor de saída
AS
BEGIN
    -- busca 1% em PARAMETROS_FIXOS e aplica sobre o salário
    SET @v_val = @p_sal * (
        SELECT valor / 100
        FROM PARAMETROS_FIXOS
        WHERE chave = 'REPOUSO_PERC'
    );
END;
GO

-- 3.2  Vale Cultura: retorna valor fixo de R$ 80,00 da tabela PARAMETROS_FIXOS
IF OBJECT_ID('SP_ValeCultura') IS NOT NULL
    DROP PROCEDURE SP_ValeCultura;
GO
CREATE PROCEDURE SP_ValeCultura
  @v_val DECIMAL(10,2) OUTPUT -- valor de saída
AS
BEGIN
    -- busca VALE_CULTURA em PARAMETROS_FIXOS
    SELECT @v_val = valor
    FROM PARAMETROS_FIXOS
    WHERE chave = 'VALE_CULTURA';
END;
GO

-- 3.3  Auxílio Alimentação: retorna R$ 750,00 fixos de PARAMETROS_FIXOS
IF OBJECT_ID('SP_AuxAlimentacao') IS NOT NULL
    DROP PROCEDURE SP_AuxAlimentacao;
GO
CREATE PROCEDURE SP_AuxAlimentacao
  @v_val DECIMAL(10,2) OUTPUT -- valor de saída
AS
BEGIN
    -- busca AUX_ALIMENTACAO em PARAMETROS_FIXOS
    SELECT @v_val = valor
    FROM PARAMETROS_FIXOS
    WHERE chave = 'AUX_ALIMENTACAO';
END;
GO

-- 3.4  Salário-Família: se salário < limite, multiplica valor por dependente
IF OBJECT_ID('SP_SalarioFamilia') IS NOT NULL
    DROP PROCEDURE SP_SalarioFamilia;
GO
CREATE PROCEDURE SP_SalarioFamilia
  @p_sal DECIMAL(10,2),      -- salário bruto
  @p_dep INT,                -- número de dependentes
  @v_val DECIMAL(10,2) OUTPUT-- valor de saída
AS
BEGIN
    DECLARE @lim DECIMAL(10,2), @vf DECIMAL(10,2);

    -- obtém limite salarial e valor por dependente
    SELECT @lim = valor FROM PARAMETROS_FIXOS WHERE chave = 'SAL_FAM_SALARIO_LIM';
    SELECT @vf  = valor FROM PARAMETROS_FIXOS WHERE chave = 'SAL_FAM_VAL_DEP';

    IF @p_sal < @lim
        SET @v_val = @vf * @p_dep; -- se abaixo do limite, paga por dependente
    ELSE
        SET @v_val = 0;            -- senão, sem benefício
END;
GO

-- 3.5  Anuênio: multiplica valor fixo por quantidade de anos trabalhados
IF OBJECT_ID('SP_Anuenio') IS NOT NULL
    DROP PROCEDURE SP_Anuenio;
GO
CREATE PROCEDURE SP_Anuenio
  @p_anos INT,               -- anos de serviço
  @v_val DECIMAL(10,2) OUTPUT-- valor de saída
AS
BEGIN
    -- busca ANUENIO_VALOR em PARAMETROS_FIXOS e multiplica pelos anos
    SELECT @v_val = valor * @p_anos
    FROM PARAMETROS_FIXOS
    WHERE chave = 'ANUENIO_VALOR';
END;
GO

-- 3.6  Gratificação por Escolaridade: aplica percentual sobre salário bruto
IF OBJECT_ID('SP_GratificacaoEscolaridade') IS NOT NULL
    DROP PROCEDURE SP_GratificacaoEscolaridade;
GO
CREATE PROCEDURE SP_GratificacaoEscolaridade
  @p_sal DECIMAL(10,2),      -- salário bruto
  @p_nivel CHAR(1),          -- nível escolaridade: S,G,E,M,D
  @v_val DECIMAL(10,2) OUTPUT-- valor de saída
AS
BEGIN
    DECLARE @perc DECIMAL(5,2);

    -- busca percentual em ESCOLARIDADE_PERC; se não achar, usa 0
    SELECT @perc = COALESCE(perc, 0)
    FROM ESCOLARIDADE_PERC
    WHERE nivel = @p_nivel;

    SET @v_val = @p_sal * (@perc / 100);
END;
GO

-- 3.7  INSS: verifica se salário cai no teto ou em faixa e calcula desconto
IF OBJECT_ID('SP_INSS') IS NOT NULL
    DROP PROCEDURE SP_INSS;
GO
CREATE PROCEDURE SP_INSS
  @p_sal_bruto DECIMAL(10,2),-- salário bruto
  @v_desc DECIMAL(10,2) OUTPUT-- valor de saída
AS
BEGIN
    DECLARE @teto DECIMAL(10,2), 
            @faixa_ini DECIMAL(10,2);

    -- busca único registro de faixa com valor_fixo>0 (teto) e faixa_ini associado
    SELECT TOP 1
        @teto = valor_fixo,
        @faixa_ini = faixa_ini
    FROM INSS_FAIXAS
    WHERE valor_fixo > 0;

    IF @p_sal_bruto >= @faixa_ini
        SET @v_desc = @teto; -- se >= 7.087,22 paga teto fixo
    ELSE
        SELECT @v_desc = @p_sal_bruto * (aliquota / 100)
        FROM INSS_FAIXAS
        WHERE @p_sal_bruto BETWEEN faixa_ini AND faixa_fim;
END;
GO

-- 3.8  Vale Transporte: se flag = 'S', aplica 6% do salário; senão zero
IF OBJECT_ID('SP_ValeTransporte') IS NOT NULL
    DROP PROCEDURE SP_ValeTransporte;
GO
CREATE PROCEDURE SP_ValeTransporte
  @p_sal_bruto DECIMAL(10,2),-- salário bruto
  @p_flag CHAR(1),           -- optante: S/N
  @v_desc DECIMAL(10,2) OUTPUT-- valor de saída
AS
BEGIN
    IF @p_flag = 'S'
        SELECT @v_desc = @p_sal_bruto * (valor / 100)
        FROM PARAMETROS_FIXOS
        WHERE chave = 'VALE_TRANS_PERC';
    ELSE
        SET @v_desc = 0; -- se não optou, sem desconto
END;
GO

-- 3.9  Plano de Saúde: se optante, soma 3,75% do salário + 1,15% por dependente
IF OBJECT_ID('SP_PlanoSaude') IS NOT NULL
    DROP PROCEDURE SP_PlanoSaude;
GO
CREATE PROCEDURE SP_PlanoSaude
  @p_sal DECIMAL(10,2),      -- salário bruto
  @p_dep INT,                -- dependentes
  @p_flag CHAR(1),           -- optante: S/N
  @v_desc DECIMAL(10,2) OUTPUT-- valor de saída
AS
BEGIN
    IF @p_flag = 'S'
    BEGIN
        DECLARE @p1 DECIMAL(5,2), 
                @p2 DECIMAL(5,2);

        -- busca percentuais de contribuição em PARAMETROS_FIXOS
        SELECT @p1 = valor FROM PARAMETROS_FIXOS WHERE chave = 'PSAUDE_PERC_FUNC';
        SELECT @p2 = valor FROM PARAMETROS_FIXOS WHERE chave = 'PSAUDE_PERC_DEP';

        -- aplica 3,75% do salário + 1,15% do salário por dependente
        SET @v_desc = @p_sal * (@p1 / 100) + @p_sal * (@p2 / 100) * @p_dep;
    END
    ELSE
        SET @v_desc = 0; -- sem plano, sem desconto
END;
GO

-- 3.10 IRRF: calcula base = bruto - INSS - dedução por dependente, aplica alíquota/faixa
IF OBJECT_ID('SP_IRRF') IS NOT NULL
    DROP PROCEDURE SP_IRRF;
GO
CREATE PROCEDURE SP_IRRF
  @p_sal_bruto DECIMAL(10,2),-- salário bruto
  @p_inss DECIMAL(10,2),     -- valor já descontado de INSS
  @p_dep INT,                -- dependentes
  @v_desc DECIMAL(10,2) OUTPUT-- valor de saída
AS
BEGIN
    DECLARE @base_calc DECIMAL(10,2), 
            @ded_dep DECIMAL(10,2),
            @aliquota DECIMAL(5,2), 
            @parcela_deduz DECIMAL(10,2);

    -- busca dedução por dependente em PARAMETROS_FIXOS
    SELECT @ded_dep = valor FROM PARAMETROS_FIXOS WHERE chave = 'DEDUCAO_DEPENDENTE';

    -- calcula base do IRRF
    SET @base_calc = @p_sal_bruto - @p_inss - (@ded_dep * @p_dep);

    -- obtém faixa correspondente em IRRF_FAIXAS
    SELECT
        @aliquota = aliquota,
        @parcela_deduz = parcela_deduz
    FROM IRRF_FAIXAS
    WHERE @base_calc BETWEEN base_ini AND base_fim;

    -- calcula imposto, subtrai parcela fixa; se negativo, zera
    SET @v_desc = (@base_calc * (@aliquota / 100)) - @parcela_deduz;
    IF @v_desc < 0
        SET @v_desc = 0;
END;
GO

-- 3.11 FGTS: calcula 8% da base (salário + proventos) da tabela PARAMETROS_FIXOS
IF OBJECT_ID('SP_FGTS') IS NOT NULL
    DROP PROCEDURE SP_FGTS;
GO
CREATE PROCEDURE SP_FGTS
  @p_base DECIMAL(10,2),    -- base de cálculo (salário+proventos)
  @v_fgts DECIMAL(10,2) OUTPUT-- valor de saída
AS
BEGIN
    SELECT @v_fgts = @p_base * (valor / 100)
    FROM PARAMETROS_FIXOS
    WHERE chave = 'FGTS';
END;
GO








-- 3.12 SP_PRINCIPAL: "Total Proventos" inclui Salário Bruto + demais proventos
-- e formata CPF no contracheque como xxx.xxx.xxx-xx
IF OBJECT_ID('SP_PRINCIPAL') IS NOT NULL
    DROP PROCEDURE SP_PRINCIPAL;
GO
CREATE PROCEDURE SP_PRINCIPAL
  @p_matric VARCHAR(4)      -- matrícula do funcionário para o contracheque
AS
BEGIN
    -- cria tabela temporária com CPF (raw), MÊS/ANO e campos de cálculo
    CREATE TABLE #tmp_folha (
        MATRICULA   VARCHAR(4),
        CPF         VARCHAR(15),
        MES_ANO     CHAR(7),
        NOME        VARCHAR(100),
        NOMECARGO   VARCHAR(100),
        SAL_BRUTO   DECIMAL(10,2),
        REPOUSO     DECIMAL(10,2),
        VL_CULT     DECIMAL(10,2),
        AUX_ALIM    DECIMAL(10,2),
        SAL_FAM     DECIMAL(10,2),
        ANUENIO     DECIMAL(10,2),
        GRAT_ESC    DECIMAL(10,2),
        PROV_TOTAL  DECIMAL(10,2),
        INSS        DECIMAL(10,2),
        VT          DECIMAL(10,2),
        PL_SAUDE    DECIMAL(10,2),
        IRRF        DECIMAL(10,2),
        DESC_TOTAL  DECIMAL(10,2),
        BASE_FGTS   DECIMAL(10,2),
        FGTS        DECIMAL(10,2),
        LIQUIDO     DECIMAL(10,2)
    );

    DECLARE @v_mat    VARCHAR(4),
            @v_sal    DECIMAL(10,2),
            @v_mesano CHAR(7) = FORMAT(GETDATE(),'MM/yyyy');

    -- cursor para cada funcionário
    DECLARE cur CURSOR FOR
        SELECT f.MATRICULA, c.SALARIO
        FROM FUNCIONARIOS f
        JOIN CARGOS c ON c.CARGO = f.CARGO;

    OPEN cur;
    FETCH NEXT FROM cur INTO @v_mat, @v_sal;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- busca dados básicos de funcionário
        DECLARE @v_nome     VARCHAR(40),
                @v_cargo    VARCHAR(40),
                @v_cpf      VARCHAR(15),
                @v_cpf_fmt  VARCHAR(14),   
                @v_cpf_lim  VARCHAR(11),   
                @v_esc      CHAR(1),
                @v_ads      DATE,
                @v_dep      INT,
                @v_vt       CHAR(1),
                @v_ps       CHAR(1);

        SELECT
            @v_nome  = f.NOME,
            @v_cpf   = f.CPF,            
            @v_cargo = c.NOMECARGO,
            @v_esc   = f.ESCOLARIDADE,
            @v_ads   = f.ADMISAO,
            @v_dep   = f.DEPENDENTES,
            @v_vt    = f.VALE_TRANSP,
            @v_ps    = f.PLANO_SAUDE
        FROM FUNCIONARIOS f
        JOIN CARGOS c ON c.CARGO = f.CARGO
        WHERE f.MATRICULA = @v_mat;

        -- remove possíveis pontos, hífens ou espaços antes de formatar
        SET @v_cpf_lim = REPLACE(REPLACE(REPLACE(@v_cpf, '.', ''), '-', ''), ' ', '');

        -- formata CPF como xxx.xxx.xxx-xx usando STUFF sobre a versão limpa
        SET @v_cpf_fmt = STUFF(
                            STUFF(
                                STUFF(@v_cpf_lim, 4, 0, '.'),
                            8, 0, '.'),
                        12, 0, '-');
        -- ex: '12345678901' -> '123.456.789-01'

        -- cálculo de anuênio preciso (ajusta se mês/dia ainda não ocorreu)
        DECLARE @v_anos INT = DATEDIFF(YEAR, @v_ads, GETDATE());
        IF (MONTH(GETDATE())*100 + DAY(GETDATE()))
           < (MONTH(@v_ads)*100 + DAY(@v_ads))
            SET @v_anos = @v_anos - 1;

        -- ===== PROVENTOS (extras) =====
        DECLARE @v_rep   DECIMAL(10,2),
                @v_vc    DECIMAL(10,2),
                @v_aux   DECIMAL(10,2),
                @v_sf    DECIMAL(10,2),
                @v_an    DECIMAL(10,2),
                @v_ge    DECIMAL(10,2),
                @v_prov_extras DECIMAL(10,2),
                @v_total_prov  DECIMAL(10,2);

        EXEC SP_RepousoRemunerado        @v_sal,      @v_rep OUTPUT;
        EXEC SP_ValeCultura              @v_vc        OUTPUT;
        EXEC SP_AuxAlimentacao           @v_aux       OUTPUT;
        EXEC SP_SalarioFamilia           @v_sal, @v_dep, @v_sf OUTPUT;
        EXEC SP_Anuenio                  @v_anos,     @v_an OUTPUT;
        EXEC SP_GratificacaoEscolaridade @v_sal, @v_esc, @v_ge OUTPUT;

        -- soma apenas os valores extras (sem incluir salário)
        SET @v_prov_extras = @v_rep + @v_vc + @v_aux + @v_sf + @v_an + @v_ge;
        -- total proventos agora inclui o salário bruto + extras
        SET @v_total_prov = @v_sal + @v_prov_extras;

        -- ===== DESCONTOS =====
        DECLARE @v_inss     DECIMAL(10,2),
                @v_vt_desc  DECIMAL(10,2),
                @v_ps_desc  DECIMAL(10,2),
                @v_irrf     DECIMAL(10,2),
                @v_desc_tot DECIMAL(10,2);

        EXEC SP_INSS           @v_sal,     @v_inss OUTPUT;
        EXEC SP_ValeTransporte @v_sal,  @v_vt,  @v_vt_desc OUTPUT;
        EXEC SP_PlanoSaude     @v_sal, @v_dep,@v_ps, @v_ps_desc OUTPUT;
        EXEC SP_IRRF           @v_sal,  @v_inss,@v_dep,  @v_irrf OUTPUT;

        SET @v_desc_tot = @v_inss + @v_vt_desc + @v_ps_desc + @v_irrf;

        -- ===== FGTS =====
        DECLARE @v_fgts       DECIMAL(10,2),
                @v_base_fgts  DECIMAL(10,2);

        -- base do FGTS segue a regra: salário bruto + extras (igual ao TOTAL_PROV)
        SET @v_base_fgts = @v_total_prov;
        EXEC SP_FGTS @v_base_fgts, @v_fgts OUTPUT;

        -- ===== SALÁRIO LÍQUIDO =====
        DECLARE @v_liq DECIMAL(10,2) = @v_total_prov - @v_desc_tot;

        -- insere linha na tabela temporária
        INSERT INTO #tmp_folha
        VALUES (
            @v_mat,         -- matrícula
            @v_cpf,         -- CPF (raw) para grid
            @v_mesano,      -- mês/ano
            @v_nome,        -- nome completo
            @v_cargo,       -- nome do cargo
            @v_sal,         -- salário bruto
            @v_rep,         -- repouso remunerado
            @v_vc,          -- vale cultura
            @v_aux,         -- auxílio alimentação
            @v_sf,          -- salário-família
            @v_an,          -- anuênio
            @v_ge,          -- gratificação escolaridade
            @v_total_prov,  -- total de proventos (salário + extras)
            @v_inss,        -- INSS
            @v_vt_desc,     -- vale transporte
            @v_ps_desc,     -- plano de saúde
            @v_irrf,        -- IRRF
            @v_desc_tot,    -- total de descontos
            @v_base_fgts,   -- base do FGTS (igual a TOTAL_PROV)
            @v_fgts,        -- valor do FGTS
            @v_liq          -- salário líquido
        );

        -- monta e imprime o contracheque para a matrícula solicitada,
        -- usando CPF formatado (@v_cpf_fmt)
        IF @v_mat = @p_matric
        BEGIN
            DECLARE @texto NVARCHAR(MAX) =
                '------------------------------------------------------------' + CHAR(13)+CHAR(10) +
                '       COMPROVANTE DE PAGAMENTO ' + @v_mesano + CHAR(13)+CHAR(10) +
                '------------------------------------------------------------' + CHAR(13)+CHAR(10) +
                '1. Matrícula        : ' + @v_mat + CHAR(13)+CHAR(10) +
                '2. CPF              : ' + @v_cpf_fmt + CHAR(13)+CHAR(10) +  -- CPF formatado
                '3. Nome             : ' + @v_nome + CHAR(13)+CHAR(10) +
                '4. Cargo            : ' + @v_cargo + CHAR(13)+CHAR(10) +
                '5. Salário Bruto    : R$ ' + FORMAT(@v_sal,'N2') + CHAR(13)+CHAR(10) +
                '----- PROVENTOS -----' + CHAR(13)+CHAR(10) +
                '6. Repouso Remuner. : ' + FORMAT(@v_rep ,'N2') + CHAR(13)+CHAR(10) +
                '7. Vale Cultura     : ' + FORMAT(@v_vc  ,'N2') + CHAR(13)+CHAR(10) +
                '8. Aux. Alimentação : ' + FORMAT(@v_aux ,'N2') + CHAR(13)+CHAR(10) +
                '9. Salário Família  : ' + FORMAT(@v_sf  ,'N2') + CHAR(13)+CHAR(10) +
                '10. Anuênio         : ' + FORMAT(@v_an  ,'N2') + CHAR(13)+CHAR(10) +
                '11. Grat. Escolarid.: ' + FORMAT(@v_ge  ,'N2') + CHAR(13)+CHAR(10) +
                '12. Total Proventos : R$ ' + FORMAT(@v_total_prov,'N2') + CHAR(13)+CHAR(10) +
                '----- DESCONTOS -----' + CHAR(13)+CHAR(10) +
                '13. INSS            : ' + FORMAT(@v_inss   ,'N2') + CHAR(13)+CHAR(10) +
                '14. Vale Transporte : ' + FORMAT(@v_vt_desc,'N2') + CHAR(13)+CHAR(10) +
                '15. Plano Saúde     : ' + FORMAT(@v_ps_desc,'N2') + CHAR(13)+CHAR(10) +
                '16. IRRF            : ' + FORMAT(@v_irrf   ,'N2') + CHAR(13)+CHAR(10) +
                'Total Descontos     : ' + FORMAT(@v_desc_tot   ,'N2') + CHAR(13)+CHAR(10) +
                '----- FGTS -----' + CHAR(13)+CHAR(10) +
                'Base FGTS           : ' + FORMAT(@v_base_fgts,'N2') + CHAR(13)+CHAR(10) +
                'Depósito (8%)       : ' + FORMAT(@v_fgts     ,'N2') + CHAR(13)+CHAR(10) +
                '-------------------------------------------' + CHAR(13)+CHAR(10) +
                '17. Salário Líquido : R$ ' + FORMAT(@v_liq,'N2') + CHAR(13)+CHAR(10) +
                '-------------------------------------------';

            PRINT @texto; -- imprime no console do SSMS
        END

        FETCH NEXT FROM cur INTO @v_mat, @v_sal;
    END

    CLOSE cur;
    DEALLOCATE cur;

    -- exibe grid com todos os funcionários ordenado por matrícula
    SELECT * FROM #tmp_folha ORDER BY MATRICULA;

    DROP TABLE #tmp_folha;
END;
GO