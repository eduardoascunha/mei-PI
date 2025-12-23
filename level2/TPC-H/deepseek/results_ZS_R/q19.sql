SELECT SUM(l_extendedprice * (1 - l_discount)) AS gross_discounted_revenue
FROM lineitem
JOIN part ON l_partkey = p_partkey
WHERE l_shipmode = 'AIR'
  AND l_shipinstruct = 'DELIVER IN PERSON'
  AND p_brand IN ('Brand#11', 'Brand#25', 'Brand#54')
  AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG', 'MED BAG', 'MED BOX', 'MED PKG', 'MED PACK', 'LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
  AND p_size BETWEEN 1 AND 50
  AND l_quantity < 30
  AND (p_brand = 'Brand#11' AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') AND l_quantity >= 4 AND l_quantity <= 14
       OR p_brand = 'Brand#25' AND p_container IN ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') AND l_quantity >= 16 AND l_quantity <= 26
       OR p_brand = 'Brand#54' AND p_container IN ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') AND l_quantity >= 29 AND l_quantity <= 39);