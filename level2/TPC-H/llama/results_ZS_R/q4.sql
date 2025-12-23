SELECT o.o_orderpriority, COUNT(*) 
FROM orders o 
JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
WHERE o.o_orderdate >= '1997-01-01' - INTERVAL '3 month' 
AND o.o_orderdate < '1997-01-01' 
AND l.l_commitdate < l.l_receiptdate 
GROUP BY o.o_orderpriority 
ORDER BY o.o_orderpriority;