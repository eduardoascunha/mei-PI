SELECT p_brand, p_type, p_size, COUNT(DISTINCT s_suppkey) AS supplier_count
FROM part, supplier, partsupp
WHERE p_partkey = ps_partkey
  AND ps_suppkey = s_suppkey
  AND p_brand != 'Brand#42'
  AND p_type NOT LIKE 'LARGE PLATED%'
  AND p_size IN (9, 7, 14, 41, 43, 38, 23, 34)
  AND s_comment NOT LIKE '%Customer%Complaint%'
GROUP BY p_brand, p_type, p_size
ORDER BY supplier_count DESC, p_brand ASC, p_type ASC, p_size ASC;