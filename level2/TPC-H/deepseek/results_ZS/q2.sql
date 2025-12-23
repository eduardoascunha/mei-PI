SELECT 
    s.s_acctbal,
    s.s_name,
    n.n_name,
    p.p_partkey,
    p.p_mfgr,
    s.s_address,
    s.s_phone,
    s.s_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size = 2
    AND p.p_type LIKE '%TIN'
    AND r.r_name = 'ASIA'
    AND ps.ps_supplycost = (
        SELECT MIN(ps_min.ps_supplycost)
        FROM partsupp ps_min
        JOIN supplier s_min ON ps_min.ps_suppkey = s_min.s_suppkey
        JOIN nation n_min ON s_min.s_nationkey = n_min.n_nationkey
        JOIN region r_min ON n_min.n_regionkey = r_min.r_regionkey
        WHERE 
            ps_min.ps_partkey = p.p_partkey
            AND r_min.r_name = 'ASIA'
    )
ORDER BY 
    s.s_acctbal DESC,
    s.s_name,
    n.n_name,
    p.p_partkey
LIMIT 100;