USE folha_pagto_demo;
GO

-- 4.1  Remove trigger existente para recriar com comentários
IF OBJECT_ID('trg_log_insert_func', 'TR') IS NOT NULL
    DROP TRIGGER trg_log_insert_func;
GO

-- 4.2  Cria trigger para log de inserção de funcionário
CREATE TRIGGER trg_log_insert_func
ON FUNCIONARIOS
AFTER INSERT
AS
BEGIN
    -- insere em LOG_INSERCAO_FUNCIONARIO data/hora + matrícula + nome dos novos funcionários
    INSERT INTO LOG_INSERCAO_FUNCIONARIO (
        data_hora,   -- registra data e hora do insert
        matricula,   -- cópia da matrícula inserida
        nome         -- cópia do nome inserido
    )
    SELECT 
        GETDATE(),   -- pega timestamp atual
        i.MATRICULA, -- matrícula de cada linha inserida
        i.NOME       -- nome de cada linha inserida
    FROM INSERTED i; -- tabela lógica com registros recém-inseridos
END;
GO
