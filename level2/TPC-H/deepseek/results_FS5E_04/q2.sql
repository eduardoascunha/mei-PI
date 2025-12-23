SELECT
    p_partkey,
    p_mfgr,
    s_name,
    s_address,
    s_nationkey,
    s_phone,
    s_acctbal,
    s_comment,
    n_name,
    ps_supplycost
FROM
    part,
    supplier,
    nation,
    region,
    partsupp
WHERE
    p_partkey = ps_partkey
    AND ps_suppkey = s_suppkey
    AND s_nationkey = n_nationkey
    AND n_regionkey = r_regionkey
    AND p_size = 2
    AND p_type LIKE '%TIN'
    AND r_name = 'ASIA'
    AND ps_supplycost = (
        SELECT MIN(ps_supplycost)
        FROM partsupp, supplier, nation, region
        WHERE ps_suppkey = s_suppkey
          AND s_nationkey = n_nationkey
          AND n_regionkey = r_regionkey
          AND ps_partkey = part.p_partkey
          AND r_name = 'ASIA'
    )
ORDER BY
    s_acctbal DESC,
    n_name,
    s_name,
    p_partkey
LIMIT 100;