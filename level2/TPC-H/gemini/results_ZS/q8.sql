SELECT
  EXTRACT(YEAR FROM o.o_orderdate) AS o_year,
  SUM(CASE
    WHEN n2.n_name = 'KENYA'
    THEN l.l_extendedprice * (1 - l.l_discount)
    ELSE 0
  END) / SUM(l.l_extendedprice * (1 - l.l_discount)) AS mkt_share
FROM
  part AS p
JOIN
  lineitem AS l ON p.p_partkey = l.l_partkey
JOIN
  supplier AS s ON l.l_suppkey = s.s_suppkey
JOIN
  orders AS o ON l.l_orderkey = o.o_orderkey
JOIN
  customer AS c ON o.o_custkey = c.c_custkey
JOIN
  nation AS n1 ON c.c_nationkey = n1.n_nationkey
JOIN
  region AS r ON n1.n_regionkey = r.r_regionkey
JOIN
  nation AS n2 ON s.s_nationkey = n2.n_nationkey
WHERE
  r.r_name = 'AFRICA'
  AND o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
  AND p.p_type = 'ECONOMY PLATED BRASS'
GROUP BY
  o_year
ORDER BY
  o_year;