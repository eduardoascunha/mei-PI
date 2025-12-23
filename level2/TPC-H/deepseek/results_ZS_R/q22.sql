WITH customer_country AS (
    SELECT 
        c_custkey,
        LEFT(c_phone, 2) AS country_code,
        c_acctbal
    FROM customer
    WHERE LEFT(c_phone, 2) IN ('30', '31', '28', '21', '26', '33', '10')
),
avg_balance AS (
    SELECT AVG(c_acctbal) AS avg_acctbal
    FROM customer
    WHERE LEFT(c_phone, 2) IN ('30', '31', '28', '21', '26', '33', '10')
),
inactive_customers AS (
    SELECT 
        cc.c_custkey,
        cc.country_code,
        cc.c_acctbal
    FROM customer_country cc
    WHERE NOT EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.o_custkey = cc.c_custkey
        AND o.o_orderdate >= CURRENT_DATE - INTERVAL '7 years'
    )
    AND cc.c_acctbal > (SELECT avg_acctbal FROM avg_balance)
    AND cc.c_acctbal > 0
)
SELECT 
    country_code,
    COUNT(*) AS customer_count,
    SUM(c_acctbal) AS total_balance
FROM inactive_customers
GROUP BY country_code
ORDER BY country_code;