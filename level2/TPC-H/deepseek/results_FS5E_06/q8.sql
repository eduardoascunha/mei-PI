SELECT
    l_year,
    sum(nation_revenue) / sum(total_revenue) as market_share
FROM
    (
        SELECT
            extract(year from l_shipdate) as l_year,
            CASE WHEN n_name = 'KENYA' THEN l_extendedprice * (1 - l_discount) ELSE 0 END as nation_revenue,
            l_extendedprice * (1 - l_discount) as total_revenue
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
            AND l_shipdate >= date '1995-01-01'
            AND l_shipdate < date '1997-01-01'
    ) as revenue_data
GROUP BY
    l_year
ORDER BY
    l_year;