**1. Introdução e Contextualização Acadêmica**

Este projeto de sistema de folha de pagamento foi desenvolvido integralmente em T-SQL para Microsoft SQL Server como segunda avaliação da disciplina **Banco de Dados 2**, ministrada no **Quarto Período do Bacharelado em Engenharia de Software** na **Universidade do Estado do Pará (UEPA)**. A estruturação deste trabalho visou não apenas consolidar conteúdos teóricos de modelagem de banco de dados, mas também preparar para demandas reais do mercado de trabalho na área de TI, ao enfatizar aspectos de projeto, implementação e manutenção de sistemas de gerenciamento de dados corporativos.

---

**2. Relevância para o Mercado de Trabalho**

1. **Adequação a Padrões Corporativos**

   * A modelagem relacional adotada (tabelas de funcionários, cargos e tabelas auxiliares de parâmetros) segue boas práticas amplamente utilizadas em sistemas de Recursos Humanos de médio e grande porte.
   * A segmentação de responsabilidades em objetos distintos (tabelas, *stored procedures* e *triggers*) facilita a manutenção, evolução e auditoria em ambientes empresariais, atendendo a requisitos de governança e compliance.

2. **Portabilidade e Escalabilidade**

   * Por utilizar recursos nativos do SQL Server (T-SQL, tabelas temporárias, cursores, transações e blocos de controle de fluxo), o projeto pode ser replicado em diferentes organizações que utilizem a plataforma Microsoft, garantindo portabilidade de scripts.
   * A adoção de tabelas de configuração (INSS\_FAIXAS, IRRF\_FAIXAS, PARAMETROS\_FIXOS etc.) permite ajustes rápidos de alíquotas e valores sem necessidade de alterar o código-fonte, favorecendo cenários de escalabilidade funcional.

3. **Competências Demandadas pelo Mercado**

   * **Modelagem Conceitual e Lógica**: compreensão de normalização, definição de chaves primárias e estrangeiras, elaboração de relacionamentos um-para-muitos e tabelas de parâmetros.
   * **Programação Avançada em SQL**: domínio de T-SQL para elaboração de *stored procedures* modulares, uso de cursores para iteração sobre conjuntos de dados e criação de *triggers* para auditoria.
   * **Tratamento de Legislação e Regras de Negócio**: aplicação de cálculos complexos (INSS, IRRF, FGTS, anuênio, gratificação por escolaridade) de acordo com normas trabalhistas, demonstrando a capacidade de traduzir requisitos legais em lógica de banco de dados.
   * **Documentação e Organização de Repositório**: estruturação de scripts em sequência lógica, comentários claros em cada etapa e padronização de nomenclatura, habilidades valorizadas para controle de versões e trabalho colaborativo.

---

**3. Principais Prós do Projeto**

1. **Modularidade e Reutilização**

   * Cada cálculo de provento, desconto ou encargo foi encapsulado em sua própria *stored procedure*, o que viabiliza testes unitários isolados e reutilização em outros módulos que demandem regras semelhantes.
   * O procedimento principal (`SP_PRINCIPAL`) atua apenas como orquestrador, invocando rotinas especializadas e agregando resultados em uma tabela temporária. Essa separação de responsabilidades aumenta a coesão e reduz o acoplamento.

2. **Parametrização Flexível**

   * O uso de tabelas auxiliares (INSS\_FAIXAS, IRRF\_FAIXAS, ESCOLARIDADE\_PERC, PARAMETROS\_FIXOS) concentra valores que, diariamente, são alterados por decretos ou políticas internas da empresa. Dessa forma, ajustes no cálculo de impostos ou benefícios podem ser feitos sem reescrever *stored procedures*.

3. **Auditoria Automática**

   * A *trigger* `trg_log_insert_func` registra inserções na tabela `FUNCIONARIOS` no momento exato do evento. Esse mecanismo de auditoria é requisito básico em muitos projetos corporativos que exigem rastreamento de alterações para fins legais e de governança.

4. **Simulação de Cenários Reais**

   * Ao inserir dados de cargos e funcionários com diferentes combinações de salário-base, dependentes, nível de escolaridade e adesão a benefícios (vale-transporte, plano de saúde), pode-se testar cenários múltiplos, aproximando-se da realidade de sistemas de faturamento de grandes organizações.

---

**4. Competências Técnicas Desenvolvidas**

1. **Elaboração de Esquema Relacional**

   * Definição de tabelas normalizadas (3ª forma normal), chaves primárias e estrangeiras, controladores de integridade referencial e índices implícitos.
   * Criação de tabelas de parâmetros e de configuração, demonstrando o entendimento de padrões como “lookup tables” e “policy tables” para constantes de negócio.

2. **Programação em T-SQL Avançada**

   * Domínio de *stored procedures* com parâmetros de entrada e saída, variáveis locais, lógica condicional (`IF… ELSE`), laços de repetição com `WHILE` e cursores para iterar sobre resultados.
   * Uso de tabelas temporárias (prefixed `#`) para agregação intermediária e geração de relatórios, revelando conhecimento de gerenciamento de recursos de cache e de otimização de consultas.

3. **Criação e Uso de *Triggers***

   * Implementação de *triggers* “AFTER INSERT” para fins de auditoria, mostrando habilidade em capturar eventos de DML (Data Manipulation Language) e registrar alterações sensíveis em tabelas de log.

4. **Formatação de Relatórios**

   * Montagem de consultas que formatam dados (por exemplo, CPF formatado com pontos e traços) e exibem resultados em formato de contracheque no console do SQL Server Management Studio (SSMS).

5. **Gerenciamento de Transações e Controle de Erros**

   * Embora não tenha havido implementação explícita de `TRY… CATCH` neste projeto, o entendimento prático sobre como transações devem ser utilizadas para garantir atomicidade em operações críticas foi reforçado pelo professor durante as aulas.

---

**5. Análise Crítica de Hard Code e Lições Aprendidas**

Durante a disciplina, foram identificados pontos de **hard code** (código fixo) que, embora funcionem para cenários acadêmicos, podem comprometer a manutenibilidade em cenários corporativos mais complexos:

1. **Valores de Dedução por Dependente no IRRF**

   * Foi adotado valor fixo de R\$ 189,59 por dependente na *stored procedure* `SP_IRRF`. No projeto real, esse valor é atualizado anualmente pela Receita Federal. Manter esse parâmetro “embutido” no código obriga a modificação direta da *procedure* a cada mudança legislativa.
   * **Correção sugerida**: extrair esse valor para a tabela `PARAMETROS_FIXOS` ou criar uma tabela específica `IRRF_DEDUCAO_DEP`, tornando-o parametrizável sem alteração de lógica T-SQL.

2. **Percentual Fixo de 1 % para “Repouso Remunerado”**

   * A *procedure* `SP_RepousoRemunerado` calcula 1 % do salário sem permitir ajustes futuros via tabela de parâmetros. Em cenários reais, esse percentual pode variar conforme acordos coletivos regionais ou alterações na legislação trabalhista.
   * **Correção sugerida**: migrar o percentual para `PARAMETROS_FIXOS` (campo `perc_repouso_remunerado`), de forma que a *procedure* leia o valor de forma dinâmica.

3. **Valor de FGTS Distribuído em `PARAMETROS_FIXOS` Versus Lógica em `SP_FGTS`**

   * Embora a alíquota de 8 % do FGTS esteja parametrizada, há situações que envolvem regimes diferenciados de recolhimento (por exemplo, contribuinte individual ou regime de MEI). O projeto restringe-se ao cálculo genérico de 8 %, o que pode não atender a todos os perfis de empregador.
   * **Recomendação de melhoria**: criar tabela de “regras de cálculo de FGTS” com diferentes regimes jurídicos, indexados por tipo de funcionário, em vez de um único valor.

4. **Cálculos de Vale-Transporte e Plano de Saúde Sem Variações por Empresa**

   * O desconto de 6 % de vale-transporte e 3,75 % (+ 1,15 % para dependentes) para plano de saúde são regras fixas no projeto. No mercado, empresas costumam negociar contratos de transporte coletivo ou planos de saúde com faixas de valores distintas.
   * **Solução proposta**: incluir tabelas específicas para “Regras de Vale-Transporte” e “Regras de Plano de Saúde” que permitam armazenar percentuais diferenciados por contrato ou faixas salariais.

5. **Faixas de INSS e IRRF Fixas em Arquivo de Script**

   * As faixas de contribuição (INSS, IRRF) estão definidas apenas nos scripts iniciais. A cada mudança de tabela de faixas (normalmente anual), é necessário remover e recriar completamente as linhas, o que pode causar inconsistência se não houver versionamento cuidadoso.
   * **Melhoria recomendada**: implementar processos de atualização automática por meio de tabelas de parametrização temporal (efetuar insert/update de forma incremental) e criar comentários indicando o ano-base de cada faixa.

6. **Uso de Cursores em `SP_PRINCIPAL`**

   * O emprego de cursores para iterar sobre a tabela `FUNCIONARIOS` facilita o entendimento didático, porém, em grandes volumes de dados, pode comprometer a performance.
   * **Sugestão de refatoração**: quando possível, substituir cursores por operações em lote (set-based), usando *joins* entre tabelas temporárias e *stored procedures* inline para gerar todos os cálculos de uma vez, aumentando eficiência.

Em síntese, a adoção de **hard code** em certos pontos — valores de dedução, percentuais fixos e regras de negócio embarcadas diretamente em *procedures*, demonstrou a importância de isolar parâmetros do código-fonte para obter flexibilidade e facilitar manutenções. Identificar essas limitações técnicas e propor soluções foi parte fundamental do processo pedagógico da disciplina.

---

**6. Diagrama Entidade-Relacionamento (DER)**
Na imagem abaixo, está representado o **Diagrama Entidade-Relacionamento (DER)** do banco de dados usado no projeto de folha de pagamento. Esse DER ilustra a estrutura de tabelas, seus principais atributos e os relacionamentos que garantem a integridade referencial:

![Captura de tela 2025-06-04 210612](https://github.com/user-attachments/assets/61dc50f1-29d6-41f8-9ac0-71590c3b955e)

1. **FUNCIONARIOS**

   * **Chave Primária**: `MATRICULA` (varchar(4))
   * Atributos: `CPF`, `NOME`, `LOCAL_NASC`, `ESCOLARIDADE` (char(1)), `CARGO` (int), `ADMISAO` (date), `NASCIMENTO` (date), `DEPENDENTES` (int), `VALE_TRANSP` (char(1)), `PLANO_SAUDE` (char(1))
   * **Relacionamentos**:

     * `CARGO` → `CARGOS.CARGO` (FK): cada funcionário está vinculado a um registro em **CARGOS**.
     * `ESCOLARIDADE` → `ESCOLARIDADE_PERC.nivel` (FK): o nível de escolaridade do funcionário (S, G, E, M, D) referencia a tabela de percentuais de gratificação.
     * É referenciada em **LOG\_INSERCAO\_FUNCIONARIO** pela coluna `matricula`.

2. **CARGOS**

   * **Chave Primária**: `CARGO` (int)
   * Atributos: `NOMECARGO` (varchar(40)), `SALARIO` (decimal(10,2))
   * **Relacionamentos**:

     * Recebe FK de **FUNCIONARIOS.CARGO**, definindo o salário-base associado a cada cargo.

3. **INSS\_FAIXAS**

   * **Chave Primária**: `id` (int, identity)
   * Atributos: `faixa_ini` (decimal(10,2)), `faixa_fim` (decimal(10,2)), `aliquota` (decimal(5,2)), `valor_fixo` (decimal(10,2))
   * **Função**: armazena faixas de contribuição ao INSS e o teto de contribuição. Seu relacionamento lógico com **FUNCIONARIOS** (através da *stored procedure* `SP_INSS`) define qual alíquota se aplica ao salário.

4. **IRRF\_FAIXAS**

   * **Chave Primária**: `id` (int, identity)
   * Atributos: `base_ini` (decimal(10,2)), `base_fim` (decimal(10,2)), `aliquota` (decimal(5,2)), `parcela_deduz` (decimal(10,2))
   * **Função**: contém as faixas de base de cálculo para o Imposto de Renda Retido na Fonte (IRRF). A *stored procedure* `SP_IRRF` utiliza essas faixas para calcular descontos.

5. **ESCOLARIDADE\_PERC**

   * **Chave Primária**: `nivel` (char(1))
   * Atributos: `perc` (decimal(5,2))
   * **Relacionamentos**:

     * `FUNCIONARIOS.ESCOLARIDADE` → `ESCOLARIDADE_PERC.nivel`: define o percentual de gratificação salarial conforme o nível de escolaridade do funcionário.

6. **PARAMETROS\_FIXOS**

   * **Chave Primária**: `chave` (varchar(30))
   * Atributos: `valor` (decimal(10,2))
   * **Função**: tabela de configuração que armazena valores fixos (por exemplo: FGTS, vale-cultura, auxílio-alimentação, anuênio, salário-família, percentuais de desconto etc.). Os *stored procedures* de cálculo (como `SP_AuxAlimentacao`, `SP_Anuenio` e `SP_FGTS`) consultam essa tabela para obter valores que podem ser alterados sem modificar a lógica T-SQL.

7. **LOG\_INSERCAO\_FUNCIONARIO**

   * **Chave Primária**: `id_log` (bigint, identity)
   * Atributos: `data_hora` (datetime), `matricula` (varchar(4)), `nome` (varchar(40))
   * **Relacionamentos**:

     * `matricula` → `FUNCIONARIOS.MATRICULA` (FK): armazena um registro de auditoria sempre que um novo funcionário é inserido em **FUNCIONARIOS** (via a *trigger* `trg_log_insert_func`).
    
> **Observações do DER:**
>
> * As linhas entre tabelas indicam chaves estrangeiras (FK).
> * Embora **PARAMETROS\_FIXOS** não tenha uma FK direta, suas entradas são referenciadas indiretamente pelos *stored procedures* que fazem os cálculos de proventos e encargos.
> * As tabelas de faixas (`INSS_FAIXAS` e `IRRF_FAIXAS`) também não possuem FKs explícitas, mas atuam como lookup tables de parâmetros de cálculo.
> * O diagrama segue padrão Crow’s Foot, destacando multiplicidades 1\:N: um cargo pode ter vários funcionários; um nível de escolaridade pode ser associado a vários funcionários; cada funcionário pode gerar vários registros de log de inserção.

---

**7. Conclusão e Avaliação Crítica**

O desenvolvimento acadêmico deste sistema de folha de pagamento ofereceu uma experiência prática valiosa ao:

* Consolidar conhecimentos teóricos de **modelagem de dados**, **normalização**, e **relacionamentos**.
* Propiciar domínio de **T-SQL avançado**, incluindo *stored procedures*, tabelas temporárias, cursores e *triggers*.
* Expor os desafios reais de abstrair **regras de negócio** (legislação trabalhista) em código de banco de dados, destacando a necessidade de parametrização adequada para o ambiente corporativo.
* Estimular a **visão crítica** frente a aspectos de desempenho (uso de cursores) e manutenibilidade (hard code), aspectos decisivos para um profissional preparado para o mercado.

Sob a perspectiva do **mercado de trabalho**, as competências desenvolvidas neste projeto estão diretamente alinhadas às exigências de empresas que buscam profissionais capazes de implementar soluções de gestão de dados e rotinas de processamento de massa. A capacidade de projetar bancos de dados robustos, criar rotinas automatizadas de cálculo e auditoria e, sobretudo, entender a importância de separar lógica de parâmetros, são diferenciais competitivos que agregam valor ao perfil do engenheiro de software.

Portanto, além do cumprimento dos requisitos acadêmicos da disciplina, este trabalho fomentou a aquisição de habilidades técnicas e analíticas indispensáveis à carreira em **Desenvolvimento de Banco de Dados** e **Engenharia de Software**, destacando a relevância de práticas recomendadas para garantir qualidade, flexibilidade e escalabilidade em projetos corporativos do mundo real.
