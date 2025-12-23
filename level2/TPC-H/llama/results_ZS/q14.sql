SELECT 
  (SUM(CASE WHEN p.p_type LIKE 'PROMO%' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) * 100) / SUM(l.l_extendedprice * (1 - l.l_discount)) AS promo_revenue
FROM 
  lineitem l,
  part p,
  orders o
WHERE 
  l.l_partkey = p.p_partkey 
  AND l.l_orderkey = o.o_orderkey 
  AND l.l_shipdate >= DATE '1996-04-01' 
  AND l.l_shipdate < DATE '1996-04-01' + INTERVAL '1 month';