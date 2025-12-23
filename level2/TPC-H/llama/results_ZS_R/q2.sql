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
  partsupp ps,
  supplier s,
  nation n,
  region r,
  part p
WHERE 
  p.p_partkey = ps.ps_partkey 
  AND ps.ps_suppkey = s.s_suppkey 
  AND s.s_nationkey = n.n_nationkey 
  AND n.n_regionkey = r.r_regionkey 
  AND r.r_name = 'ASIA' 
  AND p.p_type LIKE '%TIN' 
  AND p.p_size = 2
  AND ps.ps_supplycost = (
    SELECT 
      MIN(ps1.ps_supplycost)
    FROM 
      partsupp ps1,
      supplier s1,
      nation n1,
      region r1
    WHERE 
      ps1.ps_suppkey = s1.s_suppkey 
      AND s1.s_nationkey = n1.n_nationkey 
      AND n1.n_regionkey = r1.r_regionkey 
      AND r1.r_name = 'ASIA' 
      AND ps1.ps_partkey = p.p_partkey
  )
ORDER BY 
  s.s_acctbal DESC
LIMIT 100;