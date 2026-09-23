# Projeto ETL — Python + SQL

Projeto desenvolvido para praticar **ETL (Extract, Transform, Load)** utilizando Python e SQL, com foco no tratamento e transformação de dados de clientes e transações.

O projeto utiliza consultas SQL para transformar os dados brutos em informações sumarizadas que podem ser utilizadas posteriormente em análises e modelos de dados.

## Tecnologias utilizadas

* Python
* SQL
* SQLite
* CTEs (`WITH`)
* Window Functions
* `ROW_NUMBER()`
* Manipulação de datas
* Git e GitHub

## Estrutura do projeto

```text
.
├── etl.py
├── etl_projeto.sql
└── teste.sql
```

### `etl.py`

Responsável por carregar o arquivo SQL e executar a formatação da consulta utilizando uma data de referência.

O código utiliza um parâmetro `{date}`, permitindo alterar a data de referência da análise:

```python
with open("etl_projeto.sql") as open_file:
    query = open_file.read()

print(query.format(date='2025-01-01'))
```

### `etl_projeto.sql`

Contém a principal etapa de transformação dos dados.

A consulta utiliza diversas CTEs para organizar o processo de tratamento e criação das informações.

Entre os principais tratamentos estão:

* Tratamento das datas das transações;
* Cálculo da diferença de dias entre a transação e a data de referência;
* Cálculo da idade do cliente na data de referência;
* Quantidade de transações ao longo da vida do cliente;
* Quantidade de transações nos períodos de 7, 14, 28 e 56 dias;
* Cálculo do saldo de pontos;
* Separação de pontos positivos e negativos;
* Identificação dos produtos mais utilizados por cada cliente;
* Identificação do dia da semana com maior quantidade de transações;
* Identificação do período do dia em que o cliente mais realiza transações;
* Utilização de `ROW_NUMBER()` para identificar os maiores valores por cliente;
* Junção das informações em uma tabela final.

## Principais etapas do ETL

### 1. Tratamento das transações

A CTE `tb_transacoes` realiza o tratamento inicial dos dados da tabela `transacoes`.

São criadas informações como:

* Data e hora da transação;
* Diferença de dias em relação à data de referência;
* Hora da transação.

Também é aplicado um filtro para considerar somente transações anteriores à data de referência.

### 2. Tratamento dos clientes

A CTE `tb_cliente` realiza o tratamento da tabela de clientes e calcula a idade do cliente considerando a data de referência.

### 3. Sumário das transações

A CTE `tb_sumario_transacoes` reúne informações de cada cliente, como:

* Quantidade total de transações;
* Quantidade de transações nos últimos 7, 14, 28 e 56 dias;
* Saldo de pontos;
* Quantidade de pontos positivos;
* Quantidade de pontos negativos;
* Dias desde a última interação.

### 4. Produtos

As CTEs relacionadas aos produtos fazem a associação entre:

```text
transações → produtos
```

A partir disso, são identificados os produtos mais utilizados pelos clientes em diferentes períodos.

Para encontrar os produtos mais frequentes, é utilizada a função:

```sql
ROW_NUMBER() OVER (
    PARTITION BY IdCliente
    ORDER BY qtdeVida DESC
)
```

O mesmo conceito é aplicado para diferentes períodos.

### 5. Dia e período de maior interação

O projeto também analisa o comportamento temporal dos clientes.

São identificados:

* Dia da semana com maior quantidade de transações;
* Período do dia com maior quantidade de transações.

Os períodos são classificados como:

```text
MADRUGADA
MANHA
TARDE
NOITE
```

### 6. Feature final

Na CTE `tb_join`, todas as informações calculadas anteriormente são reunidas em uma única estrutura.

Ao final, também é calculado o indicador:

```sql
Engajamento28Vida =
qtdeTransacoes28 / qtdeTransacoesVida
```

Esse indicador representa a proporção das transações realizadas nos últimos 28 dias em relação ao total de transações do cliente.

## Feature Store

O arquivo `teste.sql` contém uma consulta para visualizar a tabela `freature_store_cliente`, organizando os registros por cliente e data de referência:

```sql
SELECT *
FROM freature_store_cliente
ORDER BY IdCliente, dtRef;
```

A ideia é utilizar as informações transformadas pelo ETL como uma base estruturada para análises posteriores.

## Objetivo do projeto

O principal objetivo foi praticar um fluxo de transformação de dados utilizando **Python e SQL**, trabalhando conceitos importantes de análise e engenharia de dados, como:

* ETL;
* CTEs;
* agregações;
* tratamento de datas;
* funções de janela;
* `ROW_NUMBER()`;
* criação de métricas;
* análise do comportamento de clientes;
* organização de dados para uma Feature Store.

## Aprendizados

Durante o desenvolvimento, foram praticados conceitos de SQL que ajudam a transformar dados brutos em informações mais estruturadas e úteis para análise.

Também foi possível trabalhar a integração entre Python e SQL, utilizando Python para carregar e parametrizar a consulta SQL através de uma data de referência.

---

Projeto desenvolvido como parte dos estudos em **Dados, Python e SQL**.
