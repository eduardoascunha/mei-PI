SELECT 
    ps_partkey,
    SUM(ps_supplycost * ps_availqty) AS value
FROM 
    partsupp
JOIN 
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey
JOIN 
    nation ON supplier.s_nationkey = nation.n_nationkey
WHERE 
    n_name = 'UNITED STATES'
GROUP BY 
    ps_partkey
HAVING 
    SUM(ps_supplycost * ps_availqty) > (
        SELECT 0.0001000000 * SUM(ps_supplycost * ps_availqty)
        FROM partsupp
        JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
        JOIN nation ON supplier.s_nationkey = nation.n_nationkey
        WHERE n_name = 'UNITED STATES'
    )
ORDER BY 
    value DESC;