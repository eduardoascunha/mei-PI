WITH avg_acct_bal AS (
  SELECT AVG(c_acctbal) AS avg_bal
  FROM customer
  WHERE c_acctbal > 0
),
country_code_cust AS (
  SELECT c_custkey, c_acctbal, 
         SUBSTRING(c_phone FROM 1 FOR 2) AS country_code
  FROM customer
)
SELECT 
  COUNT(c_custkey) AS cust_count,
  SUM(c_acctbal) AS acct_bal_sum
FROM country_code_cust
WHERE country_code IN ('30', '31', '28', '21', '26', '33', '10')
  AND c_custkey NOT IN (SELECT o_custkey FROM orders WHERE o_orderdate >= (CURRENT_DATE - INTERVAL '7 year'))
  AND c_acctbal > (SELECT avg_bal FROM avg_acct_bal);