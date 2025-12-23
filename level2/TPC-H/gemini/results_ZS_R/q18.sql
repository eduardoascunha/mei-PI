SELECT
  c_name,
  c_custkey,
  o_orderkey,
  o_orderdate,
  o_totalprice,
  SUM(l_quantity)
FROM
  customer
  JOIN orders ON c_custkey = o_custkey
  JOIN lineitem ON o_orderkey = l_orderkey
GROUP BY
  c_name,
  c_custkey,
  o_orderkey,
  o_orderdate,
  o_totalprice
HAVING
  SUM(l_quantity) > 314
ORDER BY
  o_totalprice DESC,
  o_orderdate
LIMIT 100;