SELECT s_suppkey, s_name, s_address, s_phone, total_revenue
FROM (
    SELECT s_suppkey, s_name, s_address, s_phone,
           SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
           RANK() OVER (ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) as revenue_rank
    FROM supplier, lineitem, orders, nation
    WHERE s_suppkey = l_suppkey
      AND l_orderkey = o_orderkey
      AND s_nationkey = n_nationkey
      AND o_orderdate >= DATE '1997-01-01'
      AND o_orderdate < DATE '1997-01-01' + INTERVAL '3' MONTH
      AND l_shipdate IS NOT NULL
    GROUP BY s_suppkey, s_name, s_address, s_phone
) ranked_suppliers
WHERE revenue_rank = 1
ORDER BY s_suppkey;