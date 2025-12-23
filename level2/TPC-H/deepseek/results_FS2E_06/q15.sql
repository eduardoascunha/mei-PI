SELECT s_suppkey, s_name, s_address, s_nationkey, s_phone, s_acctbal, s_comment,
       SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM supplier
JOIN lineitem ON s_suppkey = l_suppkey
JOIN orders ON l_orderkey = o_orderkey
WHERE l_shipdate >= DATE '1997-01-01'
  AND l_shipdate < DATE '1997-01-01' + INTERVAL '3' MONTH
GROUP BY s_suppkey, s_name, s_address, s_nationkey, s_phone, s_acctbal, s_comment
HAVING SUM(l_extendedprice * (1 - l_discount)) = (
    SELECT MAX(revenue)
    FROM (
        SELECT SUM(l_extendedprice * (1 - l_discount)) AS revenue
        FROM supplier
        JOIN lineitem ON s_suppkey = l_suppkey
        JOIN orders ON l_orderkey = o_orderkey
        WHERE l_shipdate >= DATE '1997-01-01'
          AND l_shipdate < DATE '1997-01-01' + INTERVAL '3' MONTH
        GROUP BY s_suppkey
    ) AS supplier_revenues
)
ORDER BY s_suppkey;