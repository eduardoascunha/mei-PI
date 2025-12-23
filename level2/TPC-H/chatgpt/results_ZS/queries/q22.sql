SELECT
SUBSTRING(c_phone FROM 1 FOR 2) AS country_code,
COUNT(*) AS num_customers,
SUM(c_acctbal) AS total_acctbal
FROM
customer
WHERE
SUBSTRING(c_phone FROM 1 FOR 2) IN ('30', '31', '28', '21', '26', '33', '10')
AND c_acctbal > 0
AND c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal > 0)
AND c_custkey NOT IN (
SELECT o_custkey
FROM orders
WHERE o_orderdate >= CURRENT_DATE - INTERVAL '7 years'
)
GROUP BY
country_code
ORDER BY
country_code;
