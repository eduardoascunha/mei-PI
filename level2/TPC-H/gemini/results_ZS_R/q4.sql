SELECT
  o_orderpriority,
  COUNT(*) AS order_count
FROM
  orders
WHERE
  o_orderdate >= DATE '1997-01-01'
  AND o_orderdate < DATE '1997-01-01' + INTERVAL '3 month'
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      l_orderkey = o_orderkey
      AND l_receiptdate > l_commitdate
  )
GROUP BY
  o_orderpriority
ORDER BY
  o_orderpriority;