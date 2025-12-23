SELECT 
    order_count_bucket, 
    COUNT(*) AS num_customers
FROM (
    SELECT 
        c.c_custkey,
        COUNT(CASE 
            WHEN o.o_comment NOT LIKE '%unusual%accounts%' 
            THEN o.o_orderkey 
        END) AS order_count,
        CASE 
            WHEN COUNT(CASE 
                WHEN o.o_comment NOT LIKE '%unusual%accounts%' 
                THEN o.o_orderkey 
            END) = 0 THEN '0'
            WHEN COUNT(CASE 
                WHEN o.o_comment NOT LIKE '%unusual%accounts%' 
                THEN o.o_orderkey 
            END) BETWEEN 1 AND 10 THEN CAST(COUNT(CASE 
                WHEN o.o_comment NOT LIKE '%unusual%accounts%' 
                THEN o.o_orderkey 
            END) AS TEXT)
            ELSE '10+'
        END AS order_count_bucket
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
) customer_orders
GROUP BY 
    order_count_bucket
ORDER BY 
    order_count_bucket;