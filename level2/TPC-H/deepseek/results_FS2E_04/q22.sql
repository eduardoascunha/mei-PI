SELECT 
    LEFT(c_phone, 2) AS country_code,
    COUNT(*) AS customer_count,
    SUM(c_acctbal) AS total_balance,
    AVG(c_acctbal) AS avg_balance
FROM 
    customer c
WHERE 
    LEFT(c_phone, 2) IN ('30', '31', '28', '21', '26', '33', '10')
    AND c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal > 0)
    AND NOT EXISTS (
        SELECT 1 
        FROM orders o 
        WHERE o.o_custkey = c.c_custkey 
        AND o.o_orderdate >= CURRENT_DATE - INTERVAL '7 years'
    )
GROUP BY 
    LEFT(c_phone, 2)
ORDER BY 
    total_balance DESC;