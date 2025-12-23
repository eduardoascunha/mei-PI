WITH avg_quantity AS (
    SELECT AVG(l_quantity) AS avg_qty
    FROM lineitem
    JOIN part ON l_partkey = p_partkey
    WHERE p_brand = 'Brand#23'
      AND p_container = 'SM CAN'
),
small_orders AS (
    SELECT l_extendedprice AS revenue
    FROM lineitem
    JOIN part ON l_partkey = p_partkey
    WHERE p_brand = 'Brand#23'
      AND p_container = 'SM CAN'
      AND l_quantity < (SELECT avg_qty * 0.2 FROM avg_quantity)
)
SELECT (SUM(revenue) / 7) AS avg_yearly_loss
FROM small_orders;