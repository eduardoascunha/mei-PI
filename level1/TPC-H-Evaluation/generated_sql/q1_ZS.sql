SELECT 
    l_returnflag, 
    l_linestatus, 
    SUM(l_extendedprice) AS sum_extendedprice, 
    SUM(l_extendedprice * (1 - l_discount)) AS sum_discounted_extendedprice, 
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_discounted_extendedprice_plus_tax, 
    AVG(l_quantity) AS avg_quantity, 
    AVG(l_extendedprice) AS avg_extendedprice, 
    AVG(l_discount) AS avg_discount, 
    COUNT(*) AS count_lineitems
FROM 
    lineitem
WHERE 
    l_shipdate <= DATE '1998-12-01' - (random() * (120 - 60) + 60)
GROUP BY 
    l_returnflag, 
    l_linestatus
ORDER BY 
    l_returnflag, 
    l_linestatus;