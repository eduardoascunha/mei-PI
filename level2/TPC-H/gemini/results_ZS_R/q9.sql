SELECT
  n_name,
  EXTRACT(YEAR FROM o_orderdate) AS o_year,
  SUM(l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity) AS sum_profit
FROM
  part
  JOIN lineitem ON p_partkey = l_partkey
  JOIN partsupp ON ps_partkey = l_partkey AND ps_suppkey = l_suppkey
  JOIN orders ON o_orderkey = l_orderkey
  JOIN supplier ON s_suppkey = l_suppkey
  JOIN nation ON n_nationkey = s_nationkey
WHERE
  p_name LIKE '%red%'
GROUP BY
  n_name,
  o_year
ORDER BY
  n_name,
  o_year DESC;