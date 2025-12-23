SELECT 
  c_custkey, 
  c_name, 
  c_acctbal, 
  c_phone, 
  c_address, 
  c_comment 
FROM 
  customer 
WHERE 
  c_custkey IN (
    SELECT 
      c_custkey 
    FROM 
      customer 
    WHERE 
      c_phone IS NOT NULL 
      AND c_acctbal > 0 
      AND c_custkey IN (
        SELECT 
          c_custkey 
        FROM 
          customer 
        WHERE 
          c_nationkey IN (
            SELECT 
              n_nationkey 
            FROM 
              nation 
            WHERE 
              n_regionkey IN (
                SELECT 
                  r_regionkey 
                FROM 
                  region 
                WHERE 
                  r_name = 'MIDDLE EAST'
              )
          )
      )
  )
  AND c_custkey NOT IN (
    SELECT 
      c_custkey 
    FROM 
      customer 
    WHERE 
      c_acctbal < 0
  )