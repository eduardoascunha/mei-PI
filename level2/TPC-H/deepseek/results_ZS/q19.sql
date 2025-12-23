SELECT SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM lineitem
JOIN part ON l_partkey = p_partkey
WHERE l_shipmode = 'AIR'
  AND l_shipinstruct = 'DELIVER IN PERSON'
  AND p_brand IN ('Brand#11', 'Brand#25', 'Brand#54')
  AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG', 
                      'MED CASE', 'MED BOX', 'MED PACK', 'MED PKG',
                      'LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
  AND p_size BETWEEN 1 AND 15
  AND (p_size BETWEEN 1 AND 5 AND p_brand = 'Brand#11' AND l_quantity < 4
       OR p_size BETWEEN 1 AND 10 AND p_brand = 'Brand#25' AND l_quantity < 16
       OR p_size BETWEEN 1 AND 15 AND p_brand = 'Brand#54' AND l_quantity < 29);