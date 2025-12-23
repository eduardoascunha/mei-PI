WITH cust_avg AS (
SELECT AVG(c_acctbal) AS avg_acctbal
FROM customer
WHERE c_acctbal > 0
),
cust_no_orders AS (
SELECT c.c_custkey, c.c_phone, c.c_acctbal
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
AND o.o_orderdate >= current_date - INTERVAL '7 years'
WHERE o.o_orderkey IS NULL
AND c.c_acctbal > (SELECT avg_acctbal FROM cust_avg)
AND LEFT(c.c_phone, 2) IN ('30', '31', '28', '21', '26', '33', '10')
)
SELECT LEFT(c_phone, 2) AS country_code,
COUNT(*) AS num_customers,
SUM(c_acctbal) AS total_acctbal
FROM cust_no_orders
GROUP BY LEFT(c_phone, 2)
ORDER BY LEFT(c_phone, 2);
