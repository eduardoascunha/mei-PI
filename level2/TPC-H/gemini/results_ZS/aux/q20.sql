SELECT s_name
FROM supplier
JOIN nation ON s_nationkey = n_nationkey
WHERE n_name = 'SAUDI ARABIA' AND s_suppkey IN (
    SELECT ps_suppkey
    FROM partsupp
    JOIN (
        SELECT l_partkey AS agg_partkey, l_suppkey AS agg_suppkey, 0.5 * sum(l_quantity) AS agg_quantity
        FROM lineitem
        WHERE l_shipdate >= '1994-01-01'
          AND l_shipdate < '1995-01-01'
        GROUP BY l_partkey, l_suppkey
    ) AS agg_lineitem ON agg_partkey = ps_partkey AND agg_suppkey = ps_suppkey
    JOIN part ON ps_partkey = p_partkey
    WHERE p_name LIKE 'brown%'
      AND ps_availqty > agg_quantity
)
ORDER BY s_name;