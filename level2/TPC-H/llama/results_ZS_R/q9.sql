SELECT 
  N.n_name, 
  EXTRACT(YEAR FROM O.o_orderdate) AS o_year, 
  SUM(L.l_extendedprice * (1 - L.l_discount) - PS.ps_supplycost * L.l_quantity) AS profit
FROM 
  part P, 
  supplier S, 
  lineitem L, 
  partsupp PS, 
  orders O, 
  nation N
WHERE 
  S.s_suppkey = L.l_suppkey 
  AND PS.ps_suppkey = L.l_suppkey 
  AND PS.ps_partkey = L.l_partkey 
  AND P.p_partkey = L.l_partkey 
  AND O.o_orderkey = L.l_orderkey 
  AND S.s_nationkey = N.n_nationkey 
  AND P.p_name LIKE '%red%'
GROUP BY 
  N.n_name, 
  EXTRACT(YEAR FROM O.o_orderdate)
ORDER BY 
  N.n_name, 
  o_year DESC;