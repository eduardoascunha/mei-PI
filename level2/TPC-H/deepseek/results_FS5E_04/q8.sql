SELECT
    n_name,
    year,
    sum(l_extendedprice * (1 - l_discount)) / total_revenue as market_share
FROM (
    SELECT
        n.n_name,
        EXTRACT(YEAR FROM o.o_orderdate) AS year,
        l.l_extendedprice,
        l.l_discount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate)) AS total_revenue
    FROM
        lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        JOIN region r ON n.n_regionkey = r.r_regionkey
        JOIN part p ON l.l_partkey = p.p_partkey
    WHERE
        r.r_name = 'AFRICA'
        AND n.n_name = 'KENYA'
        AND p.p_type = 'ECONOMY PLATED BRASS'
        AND o.o_orderdate >= DATE '1995-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
) sub
GROUP BY
    n_name,
    year,
    total_revenue
ORDER BY
    year;