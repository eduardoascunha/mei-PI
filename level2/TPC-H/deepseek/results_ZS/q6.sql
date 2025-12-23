SELECT SUM(l_extendedprice * l_discount) AS potential_revenue_increase
FROM lineitem
WHERE l_shipdate >= DATE '1994-01-01' 
  AND l_shipdate < DATE '1995-01-01'
  AND l_discount BETWEEN 0.01 AND 0.03
  AND l_quantity < 25;