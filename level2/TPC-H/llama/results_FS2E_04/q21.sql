SELECT 
    s.s_name, 
    s.s_address, 
    s.s_phone, 
    n.n_name, 
    c.c_name 
FROM 
    supplier s, 
    nation n, 
    customer c 
WHERE 
    s.s_nationkey = n.n_nationkey 
    AND s.s_acctkey = c.c_custkey 
    AND c.c_nationkey = n.n_nationkey 
    AND n.n_name = 'ETHIOPIA'