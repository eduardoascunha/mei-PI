SELECT
    LEFT(c_phone, 2) AS country_code,
    COUNT(*) AS customer_count,
    SUM(c_acctbal) AS total_balance
FROM
    customer
WHERE
    LEFT(c_phone, 2) IN ('30', '31', '28', '21', '26', '33', '10')
    AND c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal > 0)
    AND NOT EXISTS (
        SELECT 1
        FROM orders
        WHERE orders.o_custkey = customer.c_custkey
        AND orders.o_orderdate >= CURRENT_DATE - INTERVAL '7 years'
    )
GROUP BY
    LEFT(c_phone, 2)
ORDER BY
    total_balance DESC;