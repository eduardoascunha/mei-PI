SELECT
    n_name,
    EXTRACT(YEAR FROM o_orderdate) AS o_year,
    SUM(l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity) AS profit
FROM
    part,
    supplier,
    lineitem,
    orders,
    partsupp,
    nation
WHERE
    p_partkey = l_partkey
    AND l_suppkey = s_suppkey
    AND l_orderkey = o_orderkey
    AND l_partkey = ps_partkey
    AND l_suppkey = ps_suppkey
    AND s_nationkey = n_nationkey
    AND p_name LIKE '%red%'
GROUP BY
    n_name,
    EXTRACT(YEAR FROM o_orderdate)
ORDER BY
    n_name ASC,
    o_year DESC;