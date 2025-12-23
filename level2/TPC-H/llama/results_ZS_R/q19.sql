SELECT 
  SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
  lineitem,
  part
WHERE 
  p_partkey = l_partkey 
  AND l_shipmode = 'AIR' 
  AND l_shipinstruct = 'DELIVER IN PERSON'
  AND p_brand IN ('Brand#11', 'Brand#25', 'Brand#54')
  AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG', 'MED BOX', 'MED PKG', 'MED PACK', 'LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
  AND l_quantity BETWEEN 4 AND 16 
  AND p_size BETWEEN 1 AND 29;