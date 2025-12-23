SELECT
    s_name
FROM
    supplier
JOIN
    nation ON s_nationkey = n_nationkey
WHERE
    n_name = 'SAUDI ARABIA'
    AND s_suppkey IN (
        SELECT
            ps_suppkey
        FROM
            partsupp
        JOIN
            part ON p_partkey = ps_partkey
        WHERE
            p_name LIKE 'brown%'
            AND ps_availqty > (
                SELECT
                    0.5 * SUM(l_quantity)
                FROM
                    lineitem
                WHERE
                    l_partkey = ps_partkey
                    AND l_suppkey = ps_suppkey
                    AND l_shipdate >= '1994-01-01'
                    AND l_shipdate < '1995-01-01'
            )
    )
ORDER BY
    s_name;