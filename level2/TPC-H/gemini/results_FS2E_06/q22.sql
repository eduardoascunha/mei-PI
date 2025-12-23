SELECT
  SUBSTRING(c_phone FROM 1 FOR 2) AS cntrycode,
  COUNT(*) AS numcust,
  SUM(c_acctbal) AS totacctbal
FROM
  customer
WHERE
  SUBSTRING(c_phone FROM 1 FOR 2) IN ('30', '31', '28', '21', '26', '33', '10')
  AND c_acctbal > (
    SELECT
      AVG(c_acctbal)
    FROM
      customer
    WHERE
      c_acctbal > 0.00
      AND SUBSTRING(c_phone FROM 1 FOR 2) IN ('30', '31', '28', '21', '26', '33', '10')
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      orders
    WHERE
      o_custkey = c_custkey
  )
GROUP BY
  cntrycode
ORDER BY
  cntrycode;