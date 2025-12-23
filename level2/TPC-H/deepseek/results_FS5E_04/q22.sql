SELECT
    substr(c_phone, 1, 2) AS country_code,
    count(*) AS customer_count,
    avg(c_acctbal) AS avg_balance
FROM
    customer
WHERE
    substr(c_phone, 1, 2) IN ('30', '31', '28', '21', '26', '33', '10')
    AND c_acctbal > (SELECT avg(c_acctbal) FROM customer WHERE c_acctbal > 0)
    AND NOT EXISTS (
        SELECT 1
        FROM orders
        WHERE orders.o_custkey = customer.c_custkey
        AND orders.o_orderdate >= current_date - interval '7 years'
    )
GROUP BY
    substr(c_phone, 1, 2)
ORDER BY
    avg_balance DESC;