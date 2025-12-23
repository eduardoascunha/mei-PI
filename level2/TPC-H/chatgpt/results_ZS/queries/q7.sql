SELECT
supp_nation.n_name AS supplier_nation,
cust_nation.n_name AS customer_nation,
EXTRACT(YEAR FROM l_shipdate) AS l_year,
SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM
supplier s
JOIN
nation supp_nation ON s.s_nationkey = supp_nation.n_nationkey
JOIN
lineitem l ON s.s_suppkey = l.l_suppkey
JOIN
orders o ON l.l_orderkey = o.o_orderkey
JOIN
customer c ON o.o_custkey = c.c_custkey
JOIN
nation cust_nation ON c.c_nationkey = cust_nation.n_nationkey
WHERE
(
(supp_nation.n_name = 'ARGENTINA' AND cust_nation.n_name = 'KENYA')
OR
(supp_nation.n_name = 'KENYA' AND cust_nation.n_name = 'ARGENTINA')
)
AND l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
GROUP BY
supplier_nation,
customer_nation,
l_year
ORDER BY
supplier_nation,
customer_nation,
l_year;
