SELECT p_brand, p_type, p_size, COUNT(DISTINCT ps_suppkey) AS supplier_count
FROM part
JOIN partsupp ON p_partkey = ps_partkey
JOIN supplier ON ps_suppkey = s_suppkey
WHERE p_brand != 'Brand#42'
  AND p_type NOT LIKE 'LARGE PLATED%'
  AND p_size IN (9, 7, 14, 41, 43, 38, 23, 34)
  AND s_comment NOT LIKE '%Customer%Complaints%'
GROUP BY p_brand, p_type, p_size
ORDER BY supplier_count DESC, p_brand ASC, p_type ASC, p_size ASC;