SELECT 
    (SUM(CASE WHEN p_type LIKE 'PROMO%' THEN l_extendedprice * (1 - l_discount) ELSE 0 END) / 
     SUM(l_extendedprice * (1 - l_discount))) * 100 AS promo_revenue_percentage
FROM lineitem
JOIN part ON l_partkey = p_partkey
WHERE l_shipdate >= DATE '1996-04-01' 
  AND l_shipdate < DATE '1996-04-01' + INTERVAL '1 month';