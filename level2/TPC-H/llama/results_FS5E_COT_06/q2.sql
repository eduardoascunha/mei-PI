SELECT s_name, s_nationkey, s_acctbal, s_phone, n_name 
FROM supplier, nation, region 
WHERE s_nationkey = n_nationkey AND n_regionkey = r_regionkey AND s_acctbal > 100000 
AND s_phone LIKE '%TIN%' AND r_name = 'ASIA';