WITH avg_acct_bal AS (
  SELECT AVG(c_acctbal) AS avg_bal
  FROM customer
  WHERE c_acctbal > 0
),
cust_cnt AS (
  SELECT 
    COUNT(c.c_custkey) AS cust_count,
    SUM(c.c_acctbal) AS total_acct_bal
  FROM customer c
  WHERE 
    c.c_custkey NOT IN (SELECT o_custkey FROM orders WHERE o_orderdate >= (CURRENT_DATE - INTERVAL '7 year'))
    AND SUBSTRING(c.c_phone FROM 1 FOR 2) IN ('30', '31', '28', '21', '26', '33', '10')
    AND c.c_acctbal > (SELECT avg_bal FROM avg_acct_bal)
)
SELECT cust_count, total_acct_bal
FROM cust_cnt;