WITH revenue AS (
  SELECT 
    n.n_name AS nation,
    EXTRACT(YEAR FROM o.o_orderdate) AS o_year,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
  FROM 
    customer c
  JOIN 
    orders o ON c.c_custkey = o.o_custkey
  JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
  JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
  JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
  JOIN 
    region r ON n.n_regionkey = r.r_regionkey
  JOIN 
    part p ON l.l_partkey = p.p_partkey
  WHERE 
    r.r_name = 'AFRICA' AND 
    n.n_name = 'KENYA' AND 
    p.p_type = 'ECONOMY PLATED BRASS'
  GROUP BY 
    n.n_name, 
    EXTRACT(YEAR FROM o.o_orderdate)
),
total_revenue AS (
  SELECT 
    EXTRACT(YEAR FROM o.o_orderdate) AS o_year,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
  FROM 
    customer c
  JOIN 
    orders o ON c.c_custkey = o.o_custkey
  JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
  JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
  JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
  JOIN 
    region r ON n.n_regionkey = r.r_regionkey
  JOIN 
    part p ON l.l_partkey = p.p_partkey
  WHERE 
    r.r_name = 'AFRICA' AND 
    p.p_type = 'ECONOMY PLATED BRASS'
  GROUP BY 
    EXTRACT(YEAR FROM o.o_orderdate)
)
SELECT 
  r.o_year,
  r.revenue,
  r.revenue / tr.total_revenue AS mkt_share
FROM 
  revenue r
JOIN 
  total_revenue tr ON r.o_year = tr.o_year
ORDER BY 
  r.o_year;