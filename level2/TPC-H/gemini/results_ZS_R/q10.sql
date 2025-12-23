SELECT
  c_name,
  c_address,
  n_name,
  c_phone,
  c_acctbal,
  c_comment,
  SUM(l_extendedprice * (1 - l_discount)) AS revenue_lost
FROM
  customer
  JOIN orders ON c_custkey = o_custkey
  JOIN lineitem ON o_orderkey = l_orderkey
  JOIN nation ON c_nationkey = n_nationkey
WHERE
  l_returnflag = 'R'
  AND o_orderdate >= DATE '1993-08-01'
  AND o_orderdate < DATE '1993-08-01' + INTERVAL '3 month'
GROUP BY
  c_custkey,
  c_name,
  c_acctbal,
  c_phone,
  n_name,
  c_address,
  c_comment
ORDER BY
  revenue_lost DESC
LIMIT 20;