WITH tb_transacoes AS(

    SELECT 
    IdTransacao, 
    IdCliente,
    QtdePontos,
    datetime(substr(DtCriacao, 1, 19)) AS DtCriacao,
    julianday ('now') - julianday(substr(DtCriacao, 1, 10)) AS diffDate,
    CAST(strftime('%H', substr(DtCriacao, 1, 19)) AS INTEGER) AS dtHora
    FROM transacoes 
),

tb_cliente AS (

    SELECT
    IdCliente,
    datetime(substr(DtCriacao, 1, 19)) AS DtCriacao,
    julianday ('now') - julianday(substr(DtCriacao, 1, 10)) AS IdadeBase
    FROM clientes
),

tb_sumario_transacoes AS(

    SELECT 

    IdCLiente,
    count(IdTransacao) AS qtdeTransacoesVida,
    count(CASE WHEN diffDate <= 56 THEN IdTransacao END) AS qtdeTransacoes56,
    count(CASE WHEN diffDate <= 28 THEN IdTransacao END) AS qtdeTransacoes28,
    count(CASE WHEN diffDate <= 14 THEN IdTransacao END) AS qtdeTransacoes14,
    count(CASE WHEN diffDate <= 7 THEN IdTransacao END) AS qtdeTransacoes7,

    sum(qtdePontos) AS saldo,
    min(diffDate) AS diasUltimaInteracao,

    sum(CASE WHEN qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdePontosVida,
    sum(CASE WHEN qtdePontos > 0 AND diffDate <=56  THEN qtdePontos ELSE 0 END) AS qtdePontosPositivos56,
    sum(CASE WHEN qtdePontos > 0 AND diffDate <=28  THEN qtdePontos ELSE 0 END) AS qtdePontosPositivos28,
    sum(CASE WHEN qtdePontos > 0 AND diffDate <=14  THEN qtdePontos ELSE 0 END) AS qtdePontosPositivos14,
    sum(CASE WHEN qtdePontos > 0 AND diffDate <=7 THEN qtdePontos ELSE 0 END) AS qtdePontosPositivos7,

    sum(CASE WHEN qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdePontosMorte,
    sum(CASE WHEN qtdePontos < 0 AND diffDate <=56  THEN qtdePontos ELSE 0 END) AS qtdePontosNegativos56,
    sum(CASE WHEN qtdePontos < 0 AND diffDate <=28  THEN qtdePontos ELSE 0 END) AS qtdePontosNegativos28,
    sum(CASE WHEN qtdePontos < 0 AND diffDate <=14  THEN qtdePontos ELSE 0 END) AS qtdePontosNegativos14,
    sum(CASE WHEN qtdePontos < 0 AND diffDate <=7 THEN qtdePontos ELSE 0 END) AS qtdePontosNegativos7
    
    
    FROM tb_transacoes
    GROUP BY IdCliente
    ),

    tb_transacao_produto AS(
    SELECT 
    t1.*,
    t3.DescNomeProduto,
    t3.DescCategoriaProduto

    FROM tb_transacoes AS t1

    LEFT JOIN transacao_produto AS t2
    ON t1.IdTransacao = t2.IdTransacao

    LEFT JOIN  produtos AS t3 
    ON t2.IdProduto = t3.IdProduto
),

tb_cliente_produto AS(

    SELECT 
    IdCliente, 
    DescNomeProduto, 
    count(*) AS qtdeVida,
    count(CASE WHEN diffDate <= 56 THEN IdTransacao END) as qtde56,
    count(CASE WHEN diffDate <= 27 THEN IdTransacao END) as qtde27,
    count(CASE WHEN diffDate <= 14 THEN IdTransacao END) as qtde14,
    count(CASE WHEN diffDate <= 7 THEN IdTransacao END) as qtde7

    FROM tb_transacao_produto

    GROUP BY IdCliente, DescNomeProduto
),

    tb_cliente_produto_rn AS(
    SELECT
    *,
    row_number() OVER (PARTITION BY IdCliente ORDER BY qtdeVida DESC) AS rnVida,
    row_number() OVER (PARTITION BY IdCliente ORDER BY qtde56 DESC) AS rn56,
    row_number() OVER (PARTITION BY IdCliente ORDER BY qtde27 DESC) AS rn27,
    row_number() OVER (PARTITION BY IdCliente ORDER BY qtde14 DESC) AS rn14,
    row_number() OVER (PARTITION BY IdCliente ORDER BY qtde7 DESC) AS rn7

    FROM tb_cliente_produto
),

tb_cliente_dia AS(
    SELECT 
    IdCliente,
    strftime('%w', DtCriacao) AS DtDia,
    count(*)AS qtdeTransacoes

    FROM tb_transacoes

    WHERE diffDate <= 28

    GROUP BY IdCLiente, dtDia
),


tb_cliente_dia_rn AS(
    SELECT
    *,
    row_number() OVER (PARTITION BY IdCLiente ORDER BY qtdeTransacoes DESC) AS rndia

    FROM tb_cliente_dia
),

tb_cliente_periodo AS (
    SELECT 
    IdCliente,
    CASE 
        WHEN dtHora BETWEEN 7 AND 12 THEN 'manha'
        WHEN dtHora BETWEEN 13 AND 18 THEN 'tarde'
        WHEN dtHora BETWEEN 19 AND 23 THEN 'noite'
        ElSE 'MADRUGADA'
        END AS periodo,
        count(*) AS qtdeTransacao

    FROM tb_transacoes
    WHERE diffDate <= 28
    GROUP BY 1,2
),

tb_cliente_periodo_rn AS(
    SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY IdCLiente ORDER BY qtdeTransacao DESC) AS rnPeriodo
    FROM tb_cliente_periodo
),

tb_join AS(

    SELECT 
    t1.*,
    t2.IdadeBase,
    t3.DescNomeProduto AS produtoVida,
    t4.DescNomeProduto AS produto56,
    t5.DescNomeProduto AS produto28,
    t6.DescNomeProduto AS produto27,
    t7.DescNomeProduto AS produto7,
    coalesce(t8.rndia, -1) AS dtDia,
    coalesce(t9.periodo, 'SEM INFORMACAO') AS periodo

    FROM tb_sumario_transacoes as t1

    LEFT JOIN tb_cliente AS t2
    ON t1.IdCliente = t2.IdCLiente

    LEFT JOIN tb_cliente_produto_rn AS t3
    ON t1.IdCliente = t3.IdCliente
    AND t3.rnVida = 1 

    LEFT JOIN tb_cliente_produto_rn AS t4
    ON t1.IdCliente = t4.IdCliente
    AND t4.rn56 = 1 

    LEFT JOIN tb_cliente_produto_rn AS t5
    ON t1.IdCliente = t5.IdCliente
    AND t5.rn27 = 1 

    LEFT JOIN tb_cliente_produto_rn AS t6
    ON t1.IdCliente = t6.IdCliente
    AND t6.rn14 = 1 

    LEFT JOIN tb_cliente_produto_rn AS t7
    ON t1.IdCliente = t7.IdCliente
    AND t7.rn7 = 1 

    LEFT JOIN tb_cliente_dia_rn AS t8
    ON t1.IdCLiente = t8.IdCliente
    AND t8.rndia = 1

    LEFT JOIN tb_cliente_periodo_rn AS t9
    ON t1.IdCLiente = t9.IdCliente
    AND t9.rnPeriodo = 1
)

SELECT*

FROM tb_join