SELECT
p_brand,
p_type,
p_size,
COUNT(DISTINCT ps_suppkey) AS supplier_count
FROM
partsupp ps
JOIN
part p ON ps.ps_partkey = p.p_partkey
JOIN
supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE
p_brand <> 'Brand#42'
AND p_type NOT LIKE 'LARGE PLATED%'
AND p_size IN (9, 7, 14, 41, 43, 38, 23, 34)
AND s.s_comment NOT LIKE '%complaint%'
GROUP BY
p_brand, p_type, p_size
ORDER BY
supplier_count DESC,
p_brand ASC,
p_type ASC,
p_size ASC;
