SELECT 
    n1.n_name AS supplier_nation,
    n2.n_name AS customer_nation,
    EXTRACT(YEAR FROM l_shipdate) AS year,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n2 ON c.c_nationkey = n2.n_nationkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n1 ON s.s_nationkey = n1.n_nationkey
WHERE 
    ((n1.n_name = 'ARGENTINA' AND n2.n_name = 'KENYA') OR 
     (n1.n_name = 'KENYA' AND n2.n_name = 'ARGENTINA'))
    AND l.l_shipdate >= '1995-01-01' 
    AND l.l_shipdate < '1997-01-01'
GROUP BY 
    n1.n_name, n2.n_name, EXTRACT(YEAR FROM l_shipdate)
ORDER BY 
    supplier_nation, customer_nation, year;