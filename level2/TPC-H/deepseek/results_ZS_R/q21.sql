SELECT s_name
FROM supplier
JOIN nation ON s_nationkey = n_nationkey
WHERE n_name = 'ETHIOPIA'
AND s_suppkey IN (
    SELECT DISTINCT l_suppkey
    FROM lineitem l1
    JOIN orders ON l_orderkey = o_orderkey
    WHERE o_orderstatus = 'F'
    AND l_shipdate > l_commitdate
    AND NOT EXISTS (
        SELECT 1
        FROM lineitem l2
        WHERE l2.l_orderkey = l1.l_orderkey
        AND l2.l_suppkey != l1.l_suppkey
        AND l2.l_shipdate > l2.l_commitdate
    )
    AND EXISTS (
        SELECT 1
        FROM lineitem l3
        WHERE l3.l_orderkey = l1.l_orderkey
        AND l3.l_suppkey != l1.l_suppkey
    )
)
LIMIT 100;