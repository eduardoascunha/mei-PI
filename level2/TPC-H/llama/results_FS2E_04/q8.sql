SELECT 
  n1.n_name AS nation,
  SUM(l_extendedprice * (1 - l_discount)) AS total_sales
FROM 
  lineitem l,
  nation n1,
  supplier s,
  region r,
  orders o,
  lineitem l1,
  part p,
  nation n,
  part p1,
  type t
WHERE 
  l_suppkey = s_suppkey
  AND s_nationkey = n_nationkey
  AND n_regionkey = r_regionkey
  AND r_r_name = 'AFRICA'
  AND l_partkey = p_partkey
  AND p_type = 'ECONOMY ANODIZED STEEL'
  AND l1.l_orderkey = l_linenumber
  AND l1.l_linenumber = l_linenumber + 1
GROUP BY 
  n1.n_name
ORDER BY 
  total_sales DESC;