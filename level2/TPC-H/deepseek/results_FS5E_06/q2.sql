WITH min_cost_suppliers AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_supplycost,
        s_acctbal,
        s_name,
        s_address,
        s_phone,
        s_comment,
        n_name,
        p_mfgr,
        ROW_NUMBER() OVER (
            PARTITION BY ps_partkey 
            ORDER BY ps_supplycost ASC, s_acctbal DESC
        ) as rnk
    FROM 
        partsupp
        JOIN supplier ON ps_suppkey = s_suppkey
        JOIN nation ON s_nationkey = n_nationkey
        JOIN region ON n_regionkey = r_regionkey
        JOIN part ON ps_partkey = p_partkey
    WHERE 
        p_size = 2
        AND p_type LIKE '%TIN'
        AND r_name = 'ASIA'
)
SELECT 
    ps_partkey,
    p_mfgr,
    s_name,
    s_address,
    n_name,
    s_phone,
    s_acctbal,
    s_comment
FROM 
    min_cost_suppliers
WHERE 
    rnk = 1
ORDER BY 
    ps_partkey;