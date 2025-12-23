SELECT order_count, COUNT(*) AS customer_count
FROM (
    SELECT c.c_custkey, COUNT(o.o_orderkey) FILTER (
        WHERE o.o_comment NOT LIKE '%unusual%accounts%'
    ) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
) AS customer_orders
GROUP BY order_count
ORDER BY order_count;