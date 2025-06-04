**Descrição do Projeto**
Este repositório apresenta um **sistema de folha de pagamento demo** implementado em SQL Server. O objetivo principal é demonstrar, de forma organizada e didática, como estruturar um banco de dados para controle de funcionários e cargos, implementar tabelas auxiliares com faixas de cálculo (INSS, IRRF etc.), desenvolver *stored procedures* para calcular proventos e descontos, criar *triggers* para auditoria e fornecer um procedimento principal que gera o contracheque completo de cada colaborador.

O projeto é composto pelos seguintes scripts (ordenados de uso):

1. **`1 - Criando o BD e tabelas.sql`**

   * Cria o banco de dados `folha_pagto_demo` (caso não exista).
   * Define as tabelas principais:

     * `FUNCIONARIOS`: cadastro dos colaboradores (Matrícula, CPF, Nome, Cargo, Data de Admissão, Dependentes, Benefícios etc.).
     * `CARGOS`: lista de cargos com salário-base associado.
   * Define tabelas auxiliares para parâmetros fixos e faixas de cálculo:

     * `INSS_FAIXAS`: faixas de contribuição ao INSS, incluindo teto.
     * `IRRF_FAIXAS`: faixas de base de cálculo para IRRF, com alíquotas e parcela a deduzir.
     * `ESCOLARIDADE_PERC`: percentual de gratificação por nível de escolaridade.
     * `PARAMETROS_FIXOS`: parâmetros gerais (FGTS, Vale-Cultura, Auxílio Alimentação, Salário-Família, Anuênio, Vale Transporte, Plano de Saúde etc.).
     * `LOG_INSERCAO_FUNCIONARIO`: tabela de auditoria para registrar data/hora e dados ao inserir um funcionário (utilizada pela trigger).

2. **`2- Criando as procedures.sql`**

   * Contém todas as *stored procedures* responsáveis por calcular cada componente do contracheque:

     * **Pró-labore e proventos fixos ou variáveis**:

       * `SP_RepousoRemunerado`: 1% do salário bruto (valor obtido em `PARAMETROS_FIXOS`).
       * `SP_ValeCultura`: valor fixo de R\$ 80,00 (tabela `PARAMETROS_FIXOS`).
       * `SP_AuxAlimentacao`: valor fixo de R\$ 750,00 (tabela `PARAMETROS_FIXOS`).
       * `SP_SalarioFamilia`: verifica se salário bruto < limite; multiplica valor por dependente (tabela `PARAMETROS_FIXOS`).
       * `SP_Anuenio`: calcula anuênio (valor fixo por ano trabalhado, tabela `PARAMETROS_FIXOS`).
       * `SP_GratificacaoEscolaridade`: percentual sobre salário bruto conforme nível (tabela `ESCOLARIDADE_PERC`).
     * **Descontos obrigatórios e benefícios do empregador**:

       * `SP_INSS`: identifica faixa em `INSS_FAIXAS` e calcula desconto (ou paga teto, se aplicável).
       * `SP_ValeTransporte`: 6% do salário se funcionário for optante (FLAG ‘S’), senão zero.
       * `SP_PlanoSaude`: caso optante, aplica 3,75% do salário + 1,15% do salário por dependente.
       * `SP_IRRF`: subtrai INSS e dedução por dependente da base, aplica alíquota e parcela a deduzir conforme `IRRF_FAIXAS`.
       * `SP_FGTS`: 8% do total de proventos (salário + extras) conforme `PARAMETROS_FIXOS`.
     * **Procedure principal:**

       * `SP_PRINCIPAL`: percorre todos os funcionários (cursor), coleta dados de cada um (salário, dependentes, flags de benefícios etc.), executa cada *stored procedure* acima para calcular proventos e descontos, monta a tabela temporária `#tmp_folha` com todos os valores, formata o CPF para exibição e, se a matrícula consultada corresponder ao parâmetro, imprime um contracheque formatado. Ao final, exibe em grid SQL Server todos os registros de folha ordenados por matrícula.

3. **`3 - Criando o trigger.sql`**

   * Define a *trigger* `trg_log_insert_func` sobre a tabela `FUNCIONARIOS`, executada **APÓS INSERT**.
   * Sempre que um novo funcionário é inserido, registra em `LOG_INSERCAO_FUNCIONARIO` (campo `data_hora`, `matricula` e `nome`) para manter histórico/auditoria.

4. **`4 - Inserindo valores em cargos e funcionários.sql`**

   * Insere registros de exemplo em `FUNCIONARIOS`, associando cada colaborador a um cargo (`CARGOS`), preenchendo CPF, local de nascimento, nível escolaridade, data de admissão, data de nascimento, número de dependentes, flags de vale-transporte e plano de saúde.

5. **`5 - Executando.sql`**

   * Executa a *stored procedure* principal:

     ```sql
     EXEC SP_PRINCIPAL '1060';
     ```
   * Esse comando gera o contracheque do funcionário com matrícula `1060` e também retorna, em formato de *grid*, todas as folhas de pagamento geradas para todos os funcionários cadastrados.

---

### Utilidade do Projeto

* **Demonstração de boas práticas em SQL Server**:

  * Organização de um banco de dados de folha de pagamento, separando tabelas principais, tabelas auxiliares e tabelas de parâmetro.
  * Uso de *stored procedures* para encapsular cada regra de negócio (benefícios, descontos, cálculo de impostos), facilitando manutenção e testes unitários de cada componente.
  * Implementação de *trigger* para auditoria automática de inserções em tabelas sensíveis.
* **Exemplo completo de cálculo de folha**:

  * Simula todas as etapas necessárias para calcular o salário líquido de um funcionário:

    1. Obtenção de salário-base a partir do cargo.
    2. Cálculo de proventos extras (repouso remunerado, vale-cultura, auxílio alimentação, salário-família, anuênio e gratificação por escolaridade).
    3. Cálculo de descontos obrigatórios (INSS, vale-transporte, plano de saúde, IRRF).
    4. Cálculo de FGTS sobre o total de proventos.
    5. Montagem do contracheque completo (valores formatados e listados).
  * Pode ser facilmente adaptado para outros cenários (empresas de diferentes tamanhos, escalas salariais, regimes de benefício).
* **Ferramenta de aprendizado**:

  * Ideal para estudantes de Banco de Dados ou SQL Server que desejam praticar a criação de tabelas, *stored procedures*, *triggers*, variáveis, cursores, formatação de saída (formato de CPF, relatórios em console do SSMS) e uso de tabelas temporárias.
  * Serve como base para desenvolver sistemas maiores de Recursos Humanos, folha de pagamento ou ERP.
* **Flexibilidade para melhorias**:

  * Basta ajustar valores em `PARAMETROS_FIXOS` para alterar percentuais de FGTS, anuenio, auxílio-alimentação, etc.
  * É possível estender a lógica de cálculo para incluir horas-extras, adicionais noturnos, férias, décimo-terceiro salário, entre outros.
  * A arquitetura modular (cada cálculo em uma *procedure* separada) facilita a inserção de novas regras sem afetar todo o sistema.

---

### Como Usar (Passo a Passo)

1. **Pré-requisitos**

   * Ter o **SQL Server** (2012 ou superior) instalado.
   * Um cliente para executar scripts (por exemplo, **SQL Server Management Studio** ou **Azure Data Studio**).

2. **Clonar/Reproduzir o Repositório**

   * Caso esteja no GitHub, clonar com:

     ```bash
     git clone https://github.com/SEU_USUARIO/seu-repositorio-folha-pagto-demo.git
     ```
   * Navegar até a pasta do projeto:

     ```bash
     cd seu-repositorio-folha-pagto-demo
     ```

3. **Executar os Scripts na Sequência Correta**

   > **Importante**: cada arquivo deve ser executado completamente antes de partir para o próximo. Use o SSMS em modo “New Query” conectado ao servidor correto.

   1. **`1 - Criando o BD e tabelas.sql`**

      * Abra o arquivo no editor, selecione todo o conteúdo e pressione **F5** (Executar).
      * Isso criará o banco de dados `folha_pagto_demo` e todas as tabelas (FUNCIONARIOS, CARGOS, INSS\_FAIXAS, IRRF\_FAIXAS, ESCOLARIDADE\_PERC, PARAMETROS\_FIXOS, LOG\_INSERCAO\_FUNCIONARIO).

   2. **`2- Criando as procedures.sql`**

      * Ainda conectado ao banco `folha_pagto_demo`, selecione todo o script e execute.
      * As *stored procedures* para cálculo de proventos e descontos estarão agora disponíveis no banco.

   3. **`3 - Criando o trigger.sql`**

      * Conectado a `folha_pagto_demo`, execute este arquivo para criar a *trigger* `trg_log_insert_func` em `FUNCIONARIOS`.
      * A cada inserção de funcionário, um registro será gravado em `LOG_INSERCAO_FUNCIONARIO`.

   4. **`4 - Inserindo valores em cargos e funcionários.sql`**

      * Execute este script para popular a tabela `FUNCIONARIOS` com exemplos reais (códigos de funcionário, CPF, cargo, datas, número de dependentes e flags de benefícios).
      * Ao inserir cada registro, observe que `LOG_INSERCAO_FUNCIONARIO` receberá logs automáticos (trigger).

   5. **`5 - Executando.sql`**

      * Execute `EXEC SP_PRINCIPAL '1060'` para gerar o contracheque do funcionário com matrícula `1060`.
      * Caso queira visualizar o contracheque de outro colaborador, altere a string passada como parâmetro (por exemplo, `'1002'`, `'1045'`, etc.).
      * O resultado em grid exibirá, para cada funcionário cadastrado, as colunas:

        * **MATRICULA, CPF, MÊS/ANO, NOME, NOMECARGO, SAL\_BRUTO**,
        * Valores de proventos: `REPOUSO`, `VL_CULT`, `AUX_ALIM`, `SAL_FAM`, `ANUENIO`, `GRAT_ESC`, `PROV_TOTAL`,
        * Descontos: `INSS`, `VT`, `PL_SAUDE`, `IRRF`, `DESC_TOTAL`,
        * FGTS: `BASE_FGTS`, `FGTS`,
        * E Salário Líquido: `LIQUIDO`.

4. **Personalizações e Testes**

   * **Alterar dados de funcionários**:

     * Para simular novos colaboradores, basta inserir mais registros na tabela `FUNCIONARIOS` (utilizar `INSERT INTO FUNCIONARIOS (…) VALUES (…)`). A *trigger* registrará automaticamente o log de inserção.
   * **Atualizar parâmetros**:

     * Qualquer alteração de percentual (ex.: alíquota de INSS, IRRF, valores fixos de benefícios) pode ser feita diretamente na tabela `PARAMETROS_FIXOS` ou, em faixas, nas tabelas `INSS_FAIXAS` e `IRRF_FAIXAS`.
   * **Testar diferentes cenários**:

     * Experimente inserir funcionários com diferentes salários, níveis escolaridade, dependentes e flags de benefícios (VT e Plano de Saúde). Execute `SP_PRINCIPAL` para verificar se os cálculos reflitam corretamente as regras.
   * **Incluir novas regras**:

     * Para adicionar, por exemplo, cálculo de hora-extra ou adicional noturno, crie uma nova *procedure* (ex.: `SP_HoraExtra`) e integre-a dentro de `SP_PRINCIPAL` (somando no total de proventos).

---

**Estrutura de Arquivos no Repositório**

```
/
├─ 1 - Criando o BD e tabelas.sql
├─ 2- Criando as procedures.sql
├─ 3 - Criando o trigger.sql
├─ 4 - Inserindo valores em cargos e funcionarios.sql
├─ 5 - Executando.sql
└─ README.md (opcional)
```

* Cada arquivo `.sql` deve ser executado em sequência, conforme descrito acima.
* É recomendado documentar, no próprio README.md do repositório, as instruções deste tópico para orientar novos usuários/colaboradores.

---

**Considerações Finais**
Este projeto funciona como um **ponto de partida** para quem deseja aprender a montar um sistema de folha de pagamento usando apenas SQL Server, sem necessidade de linguagens de programação adicionais. A lógica de cálculo está toda encapsulada em *stored procedures* e a auditoria básica fica por conta da *trigger*. A interface de geração de relatórios é via console do SSMS (contracheque impresso e grid de resultados). Com pequenas adaptações, o sistema pode ser integrado a camadas superiores (C#, Java, Python, front-end web etc.) ou expandido para suportar outros tipos de benefício, dedução e relatórios gerenciais.
