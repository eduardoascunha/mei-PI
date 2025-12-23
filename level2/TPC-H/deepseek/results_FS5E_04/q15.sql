SELECT s_suppkey, s_name, s_address, s_nationkey, s_phone, s_acctbal, s_comment,
       SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM supplier, lineitem, orders, nation
WHERE s_suppkey = l_suppkey
  AND l_orderkey = o_orderkey
  AND s_nationkey = n_nationkey
  AND o_orderdate >= DATE '1997-01-01'
  AND o_orderdate < DATE '1997-01-01' + INTERVAL '3' MONTH
  AND l_shipdate <= o_orderdate + INTERVAL '1' MONTH
GROUP BY s_suppkey, s_name, s_address, s_nationkey, s_phone, s_acctbal, s_comment
HAVING SUM(l_extendedprice * (1 - l_discount)) = (
    SELECT MAX(revenue)
    FROM (
        SELECT SUM(l_extendedprice * (1 - l_discount)) AS revenue
        FROM supplier, lineitem, orders
        WHERE s_suppkey = l_suppkey
          AND l_orderkey = o_orderkey
          AND o_orderdate >= DATE '1997-01-01'
          AND o_orderdate < DATE '1997-01-01' + INTERVAL '3' MONTH
          AND l_shipdate <= o_orderdate + INTERVAL '1' MONTH
        GROUP BY s_suppkey
    ) AS supplier_revenues
)
ORDER BY s_suppkey;