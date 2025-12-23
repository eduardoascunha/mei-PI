SELECT
  l_orderkey,
  SUM(l_extendedprice * (1 - l_discount)) AS revenue,
  o_orderdate,
  o_shippriority
FROM
  customer
  JOIN orders ON c_custkey = o_custkey
  JOIN lineitem ON l_orderkey = o_orderkey
WHERE
  c_mktsegment = 'FURNITURE'
  AND o_orderdate < '1995-03-27'
  AND l_shipdate > '1995-03-27'
GROUP BY
  l_orderkey,
  o_orderdate,
  o_shippriority
ORDER BY
  revenue DESC
LIMIT 10;