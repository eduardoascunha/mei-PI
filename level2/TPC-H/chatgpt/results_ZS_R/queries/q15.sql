WITH supplier_revenue AS (
SELECT
s.s_suppkey,
s.s_name,
SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM
supplier s
JOIN
lineitem l ON s.s_suppkey = l.l_suppkey
WHERE
l.l_shipdate >= DATE '1997-01-01'
AND l.l_shipdate < DATE '1997-01-01' + INTERVAL '3 months'
GROUP BY
s.s_suppkey, s.s_name
),
max_revenue AS (
SELECT MAX(revenue) AS max_rev FROM supplier_revenue
)
SELECT
s.s_suppkey,
s.s_name,
s.revenue
FROM
supplier_revenue s
JOIN
max_revenue m ON s.revenue = m.max_rev
ORDER BY
s.s_suppkey;
