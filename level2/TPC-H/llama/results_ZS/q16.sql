SELECT COUNT(DISTINCT ps.ps_suppkey) AS supplier_cnt, 
       p.p_brand, 
       p.p_type, 
       p.p_size
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE p.p_brand <> 'Brand#42'
  AND p.p_type NOT LIKE 'LARGE PLATED%'
  AND p.p_size IN (9, 7, 14, 41, 43, 38, 23, 34)
  AND s.s_comment NOT LIKE '%Customer%Complaints%'
GROUP BY p.p_brand, p.p_type, p.p_size
ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC, 
         p.p_brand ASC, 
         p.p_type ASC, 
         p.p_size ASC;