SELECT s_name, s_address, s_phone
FROM supplier
JOIN nation ON s_nationkey = n_nationkey
JOIN partsupp ON s_suppkey = ps_suppkey
JOIN lineitem ON ps_partkey = l_partkey AND ps_suppkey = l_suppkey
JOIN orders ON l_orderkey = o_orderkey
WHERE n_name = 'ETHIOPIA'
  AND o_orderstatus = 'F'
  AND l_receiptdate > l_commitdate
  AND EXISTS (
    SELECT 1
    FROM lineitem l2
    WHERE l2.l_orderkey = l_orderkey
      AND l2.l_suppkey != l_suppkey
      AND l2.l_receiptdate <= l2.l_commitdate
  )
  AND NOT EXISTS (
    SELECT 1
    FROM lineitem l3
    WHERE l3.l_orderkey = l_orderkey
      AND l3.l_suppkey != l_suppkey
      AND l3.l_receiptdate > l3.l_commitdate
  )
GROUP BY s_name, s_address, s_phone
LIMIT 100;