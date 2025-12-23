SELECT
    n.n_name AS nation,
    r.r_name AS region,
    EXTRACT(YEAR FROM l_shipdate) AS year,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    SUM(CASE WHEN s.s_nationkey = n.n_nationkey THEN l_extendedprice * (1 - l_discount) ELSE 0 END) / SUM(l_extendedprice * (1 - l_discount)) AS market_share
FROM
    lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN part p ON l.l_partkey = p.p_partkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_type = 'ECONOMY PLATED BRASS'
    AND r.r_name = 'AFRICA'
    AND EXTRACT(YEAR FROM l_shipdate) IN (1995, 1996)
GROUP BY
    n.n_name,
    r.r_name,
    EXTRACT(YEAR FROM l_shipdate)
HAVING
    n.n_name = 'KENYA'
ORDER BY
    year;