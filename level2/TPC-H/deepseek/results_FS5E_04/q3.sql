SELECT
    o_orderkey,
    o_orderdate,
    o_shippriority,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM
    customer,
    orders,
    lineitem
WHERE
    c_custkey = o_custkey
    AND o_orderkey = l_orderkey
    AND c_mktsegment = 'FURNITURE'
    AND o_orderdate < DATE '1995-03-27'
    AND l_shipdate > DATE '1995-03-27'
GROUP BY
    o_orderkey,
    o_orderdate,
    o_shippriority
ORDER BY
    revenue DESC
LIMIT 10;