SELECT c.c_name, 
       c.c_acctbal, 
       n.n_name, 
       c.c_address, 
       c.c_phone, 
       c.c_comment 
FROM customer c 
JOIN nation n ON c.c_nationkey = n.n_nationkey 
WHERE n.n_regionkey = (
  SELECT r_regionkey 
  FROM region 
  WHERE r_name = 'AMERICA'
) 
AND c.c_acctbal > (
  SELECT avg(c2.c_acctbal) 
  FROM customer c2 
  JOIN nation n2 ON c2.c_nationkey = n2.n_nationkey 
  JOIN region r2 ON n2.n_regionkey = r2.r_regionkey 
  WHERE r2.r_name = 'AMERICA'
)