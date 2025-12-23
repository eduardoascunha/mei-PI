SELECT s.s_name, s.s_address, s.s_phone
FROM supplier s
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE n.n_name = 'ETHIOPIA'
  AND o.o_orderstatus = 'F'
  AND l.l_commitdate < l.l_receiptdate
  AND EXISTS (
    SELECT 1
    FROM lineitem l2
    JOIN partsupp ps2 ON l2.l_partkey = ps2.ps_partkey AND l2.l_suppkey = ps2.ps_suppkey
    WHERE l2.l_orderkey = o.o_orderkey
      AND l2.l_commitdate >= l2.l_receiptdate
  )
  AND NOT EXISTS (
    SELECT 1
    FROM lineitem l3
    JOIN partsupp ps3 ON l3.l_partkey = ps3.ps_partkey AND l3.l_suppkey = ps3.ps_suppkey
    WHERE l3.l_orderkey = o.o_orderkey
      AND l3.l_suppkey != s.s_suppkey
      AND l3.l_commitdate < l3.l_receiptdate
  )
GROUP BY s.s_name, s.s_address, s.s_phone
ORDER BY s.s_name
LIMIT 100;