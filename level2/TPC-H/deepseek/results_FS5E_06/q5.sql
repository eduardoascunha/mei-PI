SELECT
    n.n_name AS nation,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM
    lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE
    r.r_name = 'EUROPE'
    AND c.c_nationkey = s.s_nationkey
    AND l.l_shipdate >= DATE '1994-01-01'
    AND l.l_shipdate < DATE '1994-01-01' + INTERVAL '1' YEAR
GROUP BY
    n.n_name
ORDER BY
    revenue DESC;