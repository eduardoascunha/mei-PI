SELECT
    p_brand,
    p_type,
    p_size,
    COUNT(DISTINCT ps_suppkey) AS supplier_count
FROM
    part,
    partsupp
WHERE
    p_partkey = ps_partkey
    AND p_brand <> 'Brand#42'
    AND p_type NOT LIKE 'LARGE PLATED%'
    AND p_size IN (9, 7, 14, 41, 43, 38, 23, 34)
    AND NOT EXISTS (
        SELECT 1
        FROM supplier
        WHERE s_suppkey = ps_suppkey
        AND s_comment LIKE '%Better Business Bureau%'
    )
GROUP BY
    p_brand,
    p_type,
    p_size
ORDER BY
    supplier_count DESC,
    p_brand ASC,
    p_type ASC,
    p_size ASC;