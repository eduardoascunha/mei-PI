SELECT 
    n1.n_name AS supp_nation,
    n2.n_name AS cust_nation,
    EXTRACT(YEAR FROM l_shipdate) AS ship_year,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    supplier,
    nation n1,
    nation n2,
    part,
    partsupp,
    orders,
    lineitem,
    nation n3,
    region r
WHERE 
    s_nationkey = n3.n_nationkey
    AND n3.n_regionkey = r.r_regionkey
    AND r.r_name = 'AFRICA'
    AND s_suppkey = o_custkey
    AND o_orderkey = l_orderkey
    AND l_shipdate >= '1994-01-01'
    AND l_shipdate < '1995-01-01'
    AND n1.n_name = 'ARGENTINA'
    AND n2.n_name = 'BRAZIL'
GROUP BY 
    n1.n_name,
    n2.n_name
ORDER BY 
    n1.n_name,
    n2.n_name;