SELECT
  s_acctbal,
  s_name,
  n_name,
  p_partkey,
  p_mfgr,
  s_address,
  s_phone,
  s_comment
FROM
  part
  JOIN partsupp ON p_partkey = ps_partkey
  JOIN supplier ON s_suppkey = ps_suppkey
  JOIN nation ON s_nationkey = n_nationkey
  JOIN region ON n_regionkey = r_regionkey
WHERE
  p_size = 2
  AND p_type LIKE '%TIN'
  AND r_name = 'ASIA'
  AND ps_supplycost = (
    SELECT
      MIN(ps_supplycost)
    FROM
      partsupp
      JOIN supplier ON s_suppkey = ps_suppkey
      JOIN nation ON s_nationkey = n_nationkey
      JOIN region ON n_regionkey = r_regionkey
    WHERE
      p_partkey = ps_partkey
      AND r_name = 'ASIA'
  )
ORDER BY
  s_acctbal DESC,
  n_name,
  s_name,
  p_partkey
LIMIT 100;