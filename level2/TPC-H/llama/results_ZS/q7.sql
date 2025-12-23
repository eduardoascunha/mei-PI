SELECT 
  n1.n_name AS supp_nation, 
  n2.n_name AS cust_nation, 
  EXTRACT(YEAR FROM l.l_shipdate) AS l_year, 
  SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
  customer c 
  JOIN orders o ON c.c_custkey = o.o_custkey 
  JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
  JOIN supplier s ON l.l_suppkey = s.s_suppkey 
  JOIN nation n1 ON s.s_nationkey = n1.n_nationkey 
  JOIN nation n2 ON c.c_nationkey = n2.n_nationkey 
WHERE 
  n1.n_name = 'ARGENTINA' 
  AND n2.n_name = 'KENYA' 
  AND l.l_shipdate >= '1995-01-01' 
  AND l.l_shipdate <= '1996-12-31'
GROUP BY 
  n1.n_name, 
  n2.n_name, 
  EXTRACT(YEAR FROM l.l_shipdate)
ORDER BY 
  n1.n_name, 
  n2.n_name, 
  l_year;