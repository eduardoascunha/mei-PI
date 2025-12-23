SELECT
n.n_name AS nation,
EXTRACT(YEAR FROM l.l_shipdate) AS year,
SUM(l.l_extendedprice * (1 - l.l_discount) - ps.ps_supplycost * l.l_quantity) AS profit
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON s.s_suppkey = l.l_suppkey
JOIN partsupp ps ON ps.ps_partkey = p.p_partkey AND ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_name LIKE '%red%'
AND l.l_linestatus = 'F'
GROUP BY n.n_name, EXTRACT(YEAR FROM l.l_shipdate)
ORDER BY n.n_name ASC, year DESC;
