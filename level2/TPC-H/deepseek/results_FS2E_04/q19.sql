SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_discounted_revenue
FROM lineitem
JOIN part ON l_partkey = p_partkey
WHERE p_brand IN ('Brand#11', 'Brand#25', 'Brand#54')
  AND p_container IN ('SM BOX', 'SM PKG', 'MED BAG', 'MED BOX', 'MED PKG', 'LG BOX', 'LG PKG', 'LG CASE')
  AND p_size BETWEEN 1 AND 15
  AND l_shipmode = 'AIR'
  AND l_shipinstruct = 'DELIVER IN PERSON'
  AND l_quantity < 24;