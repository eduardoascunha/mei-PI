SELECT 
    o_year,
    sum(nation_volume) / sum(total_volume) as market_share
FROM (
    SELECT 
        extract(year from o_orderdate) as o_year,
        CASE 
            WHEN n_name = 'KENYA' THEN l_extendedprice * (1 - l_discount)
            ELSE 0 
        END as nation_volume,
        l_extendedprice * (1 - l_discount) as total_volume
    FROM 
        part,
        supplier,
        lineitem,
        orders,
        nation,
        region
    WHERE 
        p_partkey = l_partkey
        AND s_suppkey = l_suppkey
        AND l_orderkey = o_orderkey
        AND s_nationkey = n_nationkey
        AND n_regionkey = r_regionkey
        AND p_type = 'ECONOMY PLATED BRASS'
        AND r_name = 'AFRICA'
        AND o_orderdate >= date '1995-01-01'
        AND o_orderdate < date '1997-01-01'
) as revenue
GROUP BY 
    o_year
ORDER BY 
    o_year;