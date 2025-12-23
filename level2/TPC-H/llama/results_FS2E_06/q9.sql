SELECT 
  n_nationkey,
  n_name,
  SUM(profit) AS total_profit
FROM (
  SELECT 
    n.n_nationkey,
    l_extendedprice * (1 - l_discount) AS profit
  FROM 
    lineitem l,
    orders o,
    customer c,
    supplier s,
    nation n,
    region r
  WHERE 
    l.l_orderkey = o.o_orderkey
    AND o.o_custkey = c.c_custkey
    AND c.c_nationkey = s.s_nationkey
    AND s.s_nationkey = n.n_nationkey
    AND n.n_name LIKE '%red%'
    AND l.l_shipdate > '1995-03-27'
) AS subquery
GROUP BY 
  n_nationkey
ORDER BY 
  total_profit DESC;