SELECT 
  s.s_acctbal, 
  s.s_name, 
  n.n_name, 
  p.p_partkey, 
  p.p_mfgr, 
  s.s_address, 
  s.s_phone, 
  s.s_comment
FROM 
  supplier s, 
  nation n, 
  partsupp ps, 
  part p, 
  region r
WHERE 
  p.p_partkey = ps.ps_partkey 
  AND s.s_suppkey = ps.ps_suppkey 
  AND s.s_nationkey = n.n_nationkey 
  AND n.n_regionkey = r.r_regionkey 
  AND r.r_name = 'ASIA' 
  AND p.p_type LIKE '%TIN' 
  AND p.p_size = 2
ORDER BY 
  ps.ps_supplycost, 
  s.s_acctbal DESC
LIMIT 100;