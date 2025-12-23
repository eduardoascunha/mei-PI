SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_discounted_revenue
FROM lineitem
JOIN part ON l_partkey = p_partkey
WHERE l_shipmode = 'AIR'
  AND l_shipinstruct = 'DELIVER IN PERSON'
  AND (
    (p_brand = 'Brand#11' AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') AND p_size BETWEEN 1 AND 5)
    OR (p_brand = 'Brand#25' AND p_container IN ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') AND p_size BETWEEN 1 AND 10)
    OR (p_brand = 'Brand#54' AND p_container IN ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') AND p_size BETWEEN 1 AND 15)
  )
  AND l_quantity < 24;