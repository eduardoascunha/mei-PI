SELECT 
  SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
  SUM(l_extendedprice * l_quantity) AS total_quantity,
  COUNT(l_orderkey) AS total_orders
FROM 
  lineitem l
JOIN 
  orders o ON l.l_orderkey = o.o_orderkey
JOIN 
  customer c ON o.o_custkey = c.c_custkey
WHERE 
  l.l_shipdate >= '1996-01-01' 
  AND l.l_shipdate < '1996-02-01'
  AND l.l_linestatus = 'F'
  AND o.o_orderstatus = 'F';