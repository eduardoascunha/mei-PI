SELECT 
    SUM(l_extendedprice) * 0.2 / 7 AS avg_yearly_loss
FROM 
    lineitem
JOIN 
    part ON l_partkey = p_partkey
WHERE 
    p_brand = 'Brand#23'
    AND p_container = 'SM CAN'
    AND l_quantity < 0.2 * (
        SELECT AVG(l_quantity)
        FROM lineitem
        JOIN part ON l_partkey = p_partkey
        WHERE p_brand = 'Brand#23'
          AND p_container = 'SM CAN'
    );