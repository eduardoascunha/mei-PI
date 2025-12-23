SELECT
  cntrycode,
  count(*) AS numcust,
  sum(c_acctbal) AS acctbal
FROM (
  SELECT
    substring(c_phone, 1, 2) AS cntrycode,
    c_acctbal
  FROM
    customer
  WHERE
    substring(c_phone, 1, 2) IN ('30', '31', '28', '21', '26', '33', '10')
    AND c_acctbal > (
      SELECT
        avg(c_acctbal)
      FROM
        customer
      WHERE
        c_acctbal > 0.00
        AND substring(c_phone, 1, 2) IN ('30', '31', '28', '21', '26', '33', '10')
    )
    AND NOT EXISTS (
      SELECT
        *
      FROM
        orders
      WHERE
        o_custkey = c_custkey
    )
) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode;