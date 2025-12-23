SELECT s_suppkey, s_name, s_address, s_phone, s_acctbal, s_comment
FROM supplier
JOIN nation ON s_nationkey = n_nationkey
WHERE n_name = 'ETHIOPIA'
AND EXISTS (
    SELECT 1
    FROM lineitem l1
    JOIN orders ON l1.l_orderkey = o_orderkey
    WHERE l1.l_suppkey = s_suppkey
    AND o_orderstatus = 'F'
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
ORDER BY s_suppkey
LIMIT 100;