SELECT
  ps_partkey,
  SUM(ps_supplycost * ps_availqty) AS value
FROM
  partsupp
  JOIN supplier ON ps_suppkey = s_suppkey
  JOIN nation ON s_nationkey = n_nationkey
WHERE
  n_name = 'UNITED STATES'
GROUP BY
  ps_partkey
HAVING
  SUM(ps_supplycost * ps_availqty) > (
    SELECT
      SUM(ps_supplycost * ps_availqty) * 0.0001000000
    FROM
      partsupp
      JOIN supplier ON ps_suppkey = s_suppkey
      JOIN nation ON s_nationkey = n_nationkey
    WHERE
      n_name = 'UNITED STATES'
  )
ORDER BY
  value DESC;