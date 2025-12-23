SELECT 
    SUM(l_extendedprice * l_discount) 
FROM 
    lineitem 
WHERE 
    l_shipdate >= '1994-01-01' 
    AND l_shipdate < '1995-01-01' 
    AND l_discount BETWEEN 0.02 AND 0.09;