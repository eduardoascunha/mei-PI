SELECT
n2.n_name AS nation,
EXTRACT(YEAR FROM o.o_orderdate) AS o_year,
SUM(l.l_extendedprice * (1 - l.l_discount)) / SUM(SUM(l.l_extendedprice * (1 - l.l_discount))) OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate)) AS mkt_share
FROM
part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON s.s_suppkey = l.l_suppkey
JOIN nation n2 ON s.s_nationkey = n2.n_nationkey
JOIN region r ON r.r_regionkey = n2.n_regionkey
JOIN orders o ON o.o_orderkey = l.l_orderkey
WHERE
r.r_name = 'AFRICA'
AND p.p_type = 'ECONOMY PLATED BRASS'
AND o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
GROUP BY
n2.n_name,
EXTRACT(YEAR FROM o.o_orderdate)
HAVING
n2.n_name = 'KENYA'
ORDER BY
o_year;
