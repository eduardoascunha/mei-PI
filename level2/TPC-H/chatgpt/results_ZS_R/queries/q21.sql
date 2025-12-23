SELECT DISTINCT s.s_name, s.s_address
FROM supplier s
JOIN lineitem l ON s.s_suppkey = l.l_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE n.n_name = 'ETHIOPIA'
AND o.o_orderstatus = 'F'
AND l.l_receiptdate > l.l_commitdate
AND NOT EXISTS (
SELECT 1
FROM lineitem l2
WHERE l2.l_orderkey = l.l_orderkey
AND l2.l_suppkey <> l.l_suppkey
AND l2.l_receiptdate > l2.l_commitdate
)
LIMIT 100;
