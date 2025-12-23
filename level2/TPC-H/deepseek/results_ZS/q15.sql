WITH supplier_revenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
        JOIN lineitem l ON s.s_suppkey = l.l_suppkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1997-01-01' + INTERVAL '3 months'
    GROUP BY 
        s.s_suppkey, s.s_name
),
max_revenue AS (
    SELECT MAX(total_revenue) AS max_rev
    FROM supplier_revenue
)
SELECT 
    sr.s_suppkey,
    sr.s_name,
    sr.total_revenue
FROM 
    supplier_revenue sr
    CROSS JOIN max_revenue mr
WHERE 
    sr.total_revenue = mr.max_rev
ORDER BY 
    sr.s_suppkey;