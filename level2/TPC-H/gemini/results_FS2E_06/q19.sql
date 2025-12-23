SELECT
  SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM
  lineitem,
  part
WHERE
  p_partkey = l_partkey
  AND l_shipinstruct = 'DELIVER IN PERSON'
  AND l_shipmode IN ('AIR', 'AIR REG')
  AND (
    (
      p_brand = 'Brand#11'
      AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
      AND l_quantity >= 4
      AND l_quantity <= 4 + 10
      AND p_size BETWEEN 1 AND 5
    )
    OR (
      p_brand = 'Brand#25'
      AND p_container IN ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
      AND l_quantity >= 16
      AND l_quantity <= 16 + 10
      AND p_size BETWEEN 1 AND 10
    )
    OR (
      p_brand = 'Brand#54'
      AND p_container IN ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
      AND l_quantity >= 29
      AND l_quantity <= 29 + 10
      AND p_size BETWEEN 1 AND 15
    )
  );