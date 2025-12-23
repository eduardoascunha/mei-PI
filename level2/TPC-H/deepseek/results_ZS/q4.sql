SELECT o_orderpriority, COUNT(DISTINCT o_orderkey) AS order_count
FROM orders
JOIN lineitem ON o_orderkey = l_orderkey
WHERE o_orderdate >= DATE '1997-01-01'
  AND o_orderdate < DATE '1997-01-01' + INTERVAL '3 months'
  AND l_receiptdate > l_commitdate
GROUP BY o_orderpriority
ORDER BY o_orderpriority;