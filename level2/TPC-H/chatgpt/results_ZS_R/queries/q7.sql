SELECT
sn.n_name AS supplier_nation,
cn.n_name AS customer_nation,
EXTRACT(YEAR FROM l.l_shipdate)::int AS l_year,
SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM lineitem l
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation sn ON s.s_nationkey = sn.n_nationkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation cn ON c.c_nationkey = cn.n_nationkey
WHERE
((sn.n_name = 'ARGENTINA' AND cn.n_name = 'KENYA')
OR (sn.n_name = 'KENYA' AND cn.n_name = 'ARGENTINA'))
AND l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
GROUP BY sn.n_name, cn.n_name, l_year
ORDER BY supplier_nation ASC, customer_nation ASC, l_year ASC;
