SELECT
EXTRACT(YEAR FROM l.l_shipdate)::int AS year,
COALESCE(
SUM(CASE WHEN n.n_name = 'KENYA' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END)
/ NULLIF(SUM(l.l_extendedprice * (1 - l.l_discount)), 0),
0
) AS market_share
FROM lineitem l
JOIN part p ON l.l_partkey = p.p_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE r.r_name = 'AFRICA'
AND p.p_type = 'ECONOMY PLATED BRASS'
AND EXTRACT(YEAR FROM l.l_shipdate) IN (1995, 1996)
GROUP BY year
ORDER BY year;
