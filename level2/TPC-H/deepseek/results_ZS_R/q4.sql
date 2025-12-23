SELECT o.o_orderpriority, COUNT(DISTINCT o.o_orderkey) AS order_count
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE o.o_orderdate >= DATE '1997-01-01' 
  AND o.o_orderdate < DATE '1997-01-01' + INTERVAL '3 months'
  AND l.l_receiptdate > l.l_commitdate
GROUP BY o.o_orderpriority
ORDER BY o.o_orderpriority;