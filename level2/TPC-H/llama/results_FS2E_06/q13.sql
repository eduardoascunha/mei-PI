SELECT 
    c_custkey, 
    COUNT(o_orderkey) AS num_orders
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    c.c_custkey IS NOT NULL 
    AND o.o_orderdate >= '2020-01-01'
GROUP BY 
    c.c_custkey
ORDER BY 
    c_custkey;