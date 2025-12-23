WITH order_counts AS (
    SELECT 
        c.c_custkey,
        COUNT(CASE 
            WHEN o.o_comment NOT LIKE '%unusual%accounts%' 
            THEN o.o_orderkey 
        END) AS num_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    num_orders,
    COUNT(*) AS customer_count
FROM order_counts
GROUP BY num_orders
ORDER BY num_orders;