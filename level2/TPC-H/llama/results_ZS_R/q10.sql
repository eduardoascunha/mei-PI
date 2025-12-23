WITH revenue AS (
  SELECT 
    c.c_custkey, 
    c.c_name, 
    c.c_acctbal, 
    c.c_address, 
    n.n_name AS c_nation, 
    c.c_phone, 
    c.c_comment, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue_lost
  FROM 
    customer c
  JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
  JOIN 
    orders o ON c.c_custkey = o.o_custkey
  JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
  WHERE 
    l.l_returnflag = 'R'
    AND o.o_orderdate >= DATE '1993-08-01' - INTERVAL '3 month'
    AND o.o_orderdate < DATE '1993-08-01'
  GROUP BY 
    c.c_custkey, 
    c.c_name, 
    c.c_acctbal, 
    c.c_address, 
    n.n_name, 
    c.c_phone, 
    c.c_comment
)
SELECT 
  c_name, 
  c_address, 
  c_nation, 
  c_phone, 
  c_acctbal, 
  c_comment, 
  revenue_lost
FROM 
  revenue
ORDER BY 
  revenue_lost DESC
LIMIT 20;