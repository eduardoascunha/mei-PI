SELECT s_name, s_address, s_phone
FROM supplier
WHERE s_nationkey = (
    SELECT n_nationkey 
    FROM nation 
    WHERE n_name = 'ETHIOPIA'
)
AND s_suppkey IN (
    SELECT DISTINCT l_suppkey
    FROM lineitem l1
    JOIN orders o ON l1.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    AND l1.l_receiptdate > l1.l_commitdate
    AND EXISTS (
        SELECT 1
        FROM lineitem l2
        WHERE l2.l_orderkey = l1.l_orderkey
        AND l2.l_suppkey <> l1.l_suppkey
        AND l2.l_receiptdate <= l2.l_commitdate
    )
    AND NOT EXISTS (
        SELECT 1
        FROM lineitem l3
        WHERE l3.l_orderkey = l1.l_orderkey
        AND l3.l_suppkey <> l1.l_suppkey
        AND l3.l_receiptdate > l3.l_commitdate
    )
)
ORDER BY s_name
LIMIT 100;