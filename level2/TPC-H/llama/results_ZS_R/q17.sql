SELECT AVG(l_extendedprice) * 0.2 * 52 / 7 AS avg_yearly_loss
FROM lineitem, part
WHERE l_partkey = p_partkey 
  AND p_brand = 'Brand#23' 
  AND p_container = 'SM CAN' 
  AND l_quantity < (SELECT AVG(l_quantity) * 0.2 
                    FROM lineitem, part 
                    WHERE l_partkey = p_partkey 
                      AND p_brand = 'Brand#23' 
                      AND p_container = 'SM CAN');