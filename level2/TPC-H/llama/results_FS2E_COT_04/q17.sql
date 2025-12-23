WITH avg_quantity AS (
  SELECT 
    AVG(l_quantity) as avg_qty
  FROM 
    lineitem, 
    part
  WHERE 
    l_partkey = p_partkey 
    AND p_brand = 'Brand#23' 
    AND p_container = 'SM CAN'
)
SELECT 
  AVG(l_extendedprice) as avg_yearly_revenue_loss
FROM 
  lineitem, 
  part
WHERE 
  l_partkey = p_partkey 
  AND p_brand = 'Brand#23' 
  AND p_container = 'SM CAN'
  AND l_quantity < (SELECT avg_qty FROM avg_quantity) * 0.2;