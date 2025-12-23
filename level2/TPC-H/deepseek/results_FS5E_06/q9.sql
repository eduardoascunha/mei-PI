SELECT
    n.n_name AS nation,
    EXTRACT(YEAR FROM o.o_orderdate) AS year,
    SUM((l.l_extendedprice * (1 - l.l_discount)) - (ps.ps_supplycost * l.l_quantity)) AS profit
FROM
    part p,
    partsupp ps,
    lineitem l,
    orders o,
    supplier s,
    nation n
WHERE
    p.p_partkey = l.l_partkey
    AND p.p_partkey = ps.ps_partkey
    AND l.l_suppkey = ps.ps_suppkey
    AND l.l_orderkey = o.o_orderkey
    AND l.l_suppkey = s.s_suppkey
    AND s.s_nationkey = n.n_nationkey
    AND p.p_name LIKE '%red%'
    AND l.l_linestatus = 'F'
GROUP BY
    n.n_name,
    EXTRACT(YEAR FROM o.o_orderdate)
ORDER BY
    n.n_name ASC,
    year DESC;