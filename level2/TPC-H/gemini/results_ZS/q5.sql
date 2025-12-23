SELECT
  n.n_name,
  SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM
  customer AS c
JOIN
  orders AS o
  ON c.c_custkey = o.o_custkey
JOIN
  lineitem AS l
  ON l.l_orderkey = o.o_orderkey
JOIN
  supplier AS s
  ON l.l_suppkey = s.s_suppkey
JOIN
  nation AS n
  ON c.c_nationkey = n.n_nationkey
JOIN
  region AS r
  ON n.n_regionkey = r.r_regionkey
WHERE
  c.c_nationkey = s.s_nationkey AND r.r_name = 'EUROPE' AND o.o_orderdate >= '1994-01-01' AND o.o_orderdate < '1995-01-01'
GROUP BY
  n.n_name
ORDER BY
  revenue DESC;