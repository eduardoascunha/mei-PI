SELECT
    p_brand,
    p_type,
    p_size,
    count(DISTINCT ps_suppkey) AS supplier_cnt
FROM
    partsupp
JOIN
    part ON p_partkey = ps_partkey
WHERE
    p_brand <> 'Brand#42'
    AND p_type NOT LIKE 'LARGE PLATED%'
    AND p_size IN (9, 7, 14, 41, 43, 38, 23, 34)
    AND ps_suppkey NOT IN (
        SELECT
            s_suppkey
        FROM
            supplier
        WHERE
            s_comment LIKE '%Customer%Complaints%'
    )
GROUP BY
    p_brand,
    p_type,
    p_size
ORDER BY
    supplier_cnt DESC,
    p_brand,
    p_type,
    p_size;