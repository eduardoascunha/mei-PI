SELECT 
    EXTRACT(YEAR FROM o.o_orderdate) AS year,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(CASE WHEN n.n_name = 'KENYA' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS nation_revenue,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 0 
        THEN SUM(CASE WHEN n.n_name = 'KENYA' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) / SUM(l.l_extendedprice * (1 - l.l_discount))
        ELSE 0 
    END AS market_share
FROM 
    lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN part p ON l.l_partkey = p.p_partkey
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'AFRICA'
    AND p.p_type = 'ECONOMY PLATED BRASS'
    AND EXTRACT(YEAR FROM o.o_orderdate) IN (1995, 1996)
GROUP BY 
    EXTRACT(YEAR FROM o.o_orderdate)
ORDER BY 
    year;