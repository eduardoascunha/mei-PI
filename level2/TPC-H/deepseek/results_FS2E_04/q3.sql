SELECT
    o_orderpriority,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM
    orders
JOIN
    lineitem ON o_orderkey = l_orderkey
JOIN
    customer ON o_custkey = c_custkey
WHERE
    c_mktsegment = 'FURNITURE'
    AND o_orderdate < DATE '1995-03-27'
    AND l_shipdate > DATE '1995-03-27'
GROUP BY
    o_orderkey,
    o_orderpriority
ORDER BY
    revenue DESC
LIMIT 10;