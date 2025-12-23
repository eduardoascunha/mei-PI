SELECT
    EXTRACT(YEAR FROM o_orderdate) AS o_year,
    SUM(CASE
        WHEN n1.n_name = 'KENYA' THEN l_extendedprice * (1 - l_discount)
        ELSE 0
    END) / SUM(l_extendedprice * (1 - l_discount)) AS mkt_share
FROM
    part
JOIN
    lineitem ON p_partkey = l_partkey
JOIN
    supplier ON s_suppkey = l_suppkey
JOIN
    orders ON l_orderkey = o_orderkey
JOIN
    customer ON o_custkey = c_custkey
JOIN
    nation n1 ON s_nationkey = n1.n_nationkey
JOIN
    nation n2 ON c_nationkey = n2.n_nationkey
JOIN
    region ON n2.n_regionkey = r_regionkey
WHERE
    r_name = 'AFRICA'
    AND o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
    AND p_type = 'ECONOMY PLATED BRASS'
GROUP BY
    o_year
ORDER BY
    o_year;