SELECT
    p_brand,
    p_type,
    p_size,
    COUNT(DISTINCT ps_suppkey) AS supplier_cnt
FROM
    partsupp,
    part,
    supplier
WHERE
    ps_partkey = p_partkey
    AND ps_suppkey = s_suppkey
    AND p_brand <> 'Brand#42'
    AND p_type NOT LIKE 'LARGE PLATED%'
    AND p_size IN (9, 7, 14, 41, 43, 38, 23, 34)
    AND s_comment NOT LIKE '%Better Business Bureau%'
GROUP BY
    p_brand,
    p_type,
    p_size
ORDER BY
    supplier_cnt DESC,
    p_brand ASC,
    p_type ASC,
    p_size ASC;