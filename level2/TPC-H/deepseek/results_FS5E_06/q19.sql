SELECT SUM(l_extendedprice * (1 - l_discount)) AS gross_discounted_revenue
FROM lineitem
JOIN part ON l_partkey = p_partkey
WHERE l_shipmode = 'AIR'
  AND l_shipinstruct = 'DELIVER IN PERSON'
  AND p_brand IN ('Brand#11', 'Brand#25', 'Brand#54')
  AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG', 'MED BAG', 'MED BOX', 'MED PKG', 'MED PACK', 'LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
  AND p_size BETWEEN 1 AND 15
  AND l_quantity < 4
UNION ALL
SELECT SUM(l_extendedprice * (1 - l_discount)) AS gross_discounted_revenue
FROM lineitem
JOIN part ON l_partkey = p_partkey
WHERE l_shipmode = 'AIR'
  AND l_shipinstruct = 'DELIVER IN PERSON'
  AND p_brand IN ('Brand#11', 'Brand#25', 'Brand#54')
  AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG', 'MED BAG', 'MED BOX', 'MED PKG', 'MED PACK', 'LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
  AND p_size BETWEEN 1 AND 15
  AND l_quantity >= 4 AND l_quantity < 16
UNION ALL
SELECT SUM(l_extendedprice * (1 - l_discount)) AS gross_discounted_revenue
FROM lineitem
JOIN part ON l_partkey = p_partkey
WHERE l_shipmode = 'AIR'
  AND l_shipinstruct = 'DELIVER IN PERSON'
  AND p_brand IN ('Brand#11', 'Brand#25', 'Brand#54')
  AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG', 'MED BAG', 'MED BOX', 'MED PKG', 'MED PACK', 'LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
  AND p_size BETWEEN 1 AND 15
  AND l_quantity >= 16 AND l_quantity < 29
UNION ALL
SELECT SUM(l_extendedprice * (1 - l_discount)) AS gross_discounted_revenue
FROM lineitem
JOIN part ON l_partkey = p_partkey
WHERE l_shipmode = 'AIR'
  AND l_shipinstruct = 'DELIVER IN PERSON'
  AND p_brand IN ('Brand#11', 'Brand#25', 'Brand#54')
  AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG', 'MED BAG', 'MED BOX', 'MED PKG', 'MED PACK', 'LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
  AND p_size BETWEEN 1 AND 15
  AND l_quantity >= 29;