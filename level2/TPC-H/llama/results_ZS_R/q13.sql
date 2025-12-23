WITH cust_orders AS (
  SELECT c.c_custkey, COUNT(o.o_orderkey) AS num_orders
  FROM customer c
  LEFT JOIN orders o ON c.c_custkey = o.o_custkey
  WHERE o.o_orderkey IS NULL OR o.o_comment NOT LIKE '%unusual accounts%'
  GROUP BY c.c_custkey
)
SELECT num_orders, COUNT(*) AS num_customers
FROM cust_orders
GROUP BY num_orders
ORDER BY num_orders;