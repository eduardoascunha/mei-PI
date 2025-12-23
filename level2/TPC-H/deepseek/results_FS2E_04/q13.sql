SELECT 
    order_count_bucket, 
    COUNT(*) AS customer_count
FROM (
    SELECT 
        c.c_custkey,
        COUNT(CASE WHEN o.o_comment NOT LIKE '%unusual%accounts%' THEN o.o_orderkey END) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
) AS customer_orders
GROUP BY 
    order_count
ORDER BY 
    order_count;