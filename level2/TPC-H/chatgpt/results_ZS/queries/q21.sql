SELECT DISTINCT s.s_suppkey, s.s_name, s.s_address, s.s_phone
FROM supplier s
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN lineitem l ON s.s_suppkey = l.l_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE n.n_name = 'ETHIOPIA'
AND o.o_orderstatus = 'F'
AND l.l_commitdate < l.l_receiptdate
AND NOT EXISTS (
SELECT 1
FROM lineitem l2
WHERE l2.l_orderkey = l.l_orderkey
AND l2.l_suppkey <> l.l_suppkey
AND l2.l_commitdate >= l2.l_receiptdate
)
LIMIT 100;
