WITH revenue_data AS (
    SELECT 
        EXTRACT(YEAR FROM l_shipdate) AS year,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    JOIN 
        orders ON l_orderkey = o_orderkey
    JOIN 
        customer ON o_custkey = c_custkey
    JOIN 
        nation cust_nation ON c_nationkey = cust_nation.n_nationkey
    JOIN 
        region ON cust_nation.n_regionkey = r_regionkey
    JOIN 
        part ON l_partkey = p_partkey
    JOIN 
        partsupp ON l_partkey = ps_partkey AND l_suppkey = ps_suppkey
    JOIN 
        supplier ON ps_suppkey = s_suppkey
    JOIN 
        nation supp_nation ON s_nationkey = supp_nation.n_nationkey
    WHERE 
        r_name = 'AFRICA'
        AND p_type = 'ECONOMY PLATED BRASS'
        AND EXTRACT(YEAR FROM l_shipdate) IN (1995, 1996)
    GROUP BY 
        EXTRACT(YEAR FROM l_shipdate)
),
nation_revenue AS (
    SELECT 
        EXTRACT(YEAR FROM l_shipdate) AS year,
        SUM(l_extendedprice * (1 - l_discount)) AS nation_revenue
    FROM 
        lineitem
    JOIN 
        orders ON l_orderkey = o_orderkey
    JOIN 
        customer ON o_custkey = c_custkey
    JOIN 
        nation cust_nation ON c_nationkey = cust_nation.n_nationkey
    JOIN 
        region ON cust_nation.n_regionkey = r_regionkey
    JOIN 
        part ON l_partkey = p_partkey
    JOIN 
        partsupp ON l_partkey = ps_partkey AND l_suppkey = ps_suppkey
    JOIN 
        supplier ON ps_suppkey = s_suppkey
    JOIN 
        nation supp_nation ON s_nationkey = supp_nation.n_nationkey
    WHERE 
        r_name = 'AFRICA'
        AND p_type = 'ECONOMY PLATED BRASS'
        AND supp_nation.n_name = 'KENYA'
        AND EXTRACT(YEAR FROM l_shipdate) IN (1995, 1996)
    GROUP BY 
        EXTRACT(YEAR FROM l_shipdate)
)
SELECT 
    rd.year,
    COALESCE(nr.nation_revenue / NULLIF(rd.total_revenue, 0), 0) AS market_share
FROM 
    revenue_data rd
LEFT JOIN 
    nation_revenue nr ON rd.year = nr.year
ORDER BY 
    rd.year;