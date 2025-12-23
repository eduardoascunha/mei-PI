SELECT 
  s_suppkey, 
  s_name, 
  s_address, 
  s_phone, 
  s_acctbal, 
  s_comment 
FROM 
  supplier 
WHERE 
  s_suppkey IN (
    SELECT 
      s_suppkey 
    FROM 
      supplier 
    WHERE 
      s_acctbal = (
        SELECT 
          MAX(s_acctbal) 
        FROM 
          supplier
      )
  )
  AND s_acctbal = (
    SELECT 
      MAX(s_acctbal) 
    FROM 
      supplier
  );