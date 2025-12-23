SELECT 
  l.l_shipmode, 
  COUNT(CASE WHEN o.o_orderpriority IN ('1-URGENT', '2-HIGH') THEN 1 ELSE NULL END) AS high_line_count,
  COUNT(CASE WHEN o.o_orderpriority NOT IN ('1-URGENT', '2-HIGH') THEN 1 ELSE NULL END) AS low_line_count
FROM 
  lineitem l
JOIN 
  orders o ON l.l_orderkey = o.o_orderkey
WHERE 
  l.l_receiptdate > l.l_commitdate 
  AND l.l_shipdate < l.l_commitdate 
  AND l.l_shipmode IN ('FOB', 'MAIL') 
  AND o.o_orderdate >= '1996-01-01' 
  AND o.o_orderdate < '1997-01-01'
GROUP BY 
  l.l_shipmode