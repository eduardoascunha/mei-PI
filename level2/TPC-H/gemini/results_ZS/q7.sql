SELECT
  n2.n_name AS supp_nation,
  n1.n_name AS cust_nation,
  EXTRACT(YEAR FROM l.l_shipdate) AS l_year,
  SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM
  supplier AS s
JOIN
  lineitem AS l
  ON s.s_suppkey = l.l_suppkey
JOIN
  orders AS o
  ON o.o_orderkey = l.l_orderkey
JOIN
  customer AS c
  ON c.c_custkey = o.o_custkey
JOIN
  nation AS n1
  ON c.c_nationkey = n1.n_nationkey
JOIN
  nation AS n2
  ON s.s_nationkey = n2.n_nationkey
WHERE
  (
    (n1.n_name = 'ARGENTINA' AND n2.n_name = 'KENYA')
    OR (n1.n_name = 'KENYA' AND n2.n_name = 'ARGENTINA')
  )
  AND l.l_shipdate BETWEEN '1995-01-01' AND '1996-12-31'
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year;