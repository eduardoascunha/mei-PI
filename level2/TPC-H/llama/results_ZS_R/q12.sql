SELECT 
    l.l_shipmode AS shipmode, 
    COUNT(DISTINCT l.l_orderkey) AS num_orders
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipdate >= '1996-01-01' 
    AND l.l_shipdate < '1997-01-01'
    AND l.l_commitdate >= '1996-01-01'
    AND l.l_commitdate < '1997-01-01'
    AND c.c_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'UNITED STATES')
GROUP BY 
    l.l_shipmode
ORDER BY 
    COUNT(l.l_shipmode) DESC;