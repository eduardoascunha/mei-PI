WITH target_parts AS (
SELECT p_partkey
FROM part
WHERE p_brand = 'Brand#23'
AND p_container = 'SM CAN'
),
avg_quantity AS (
SELECT l_partkey, AVG(l_quantity) AS avg_qty
FROM lineitem
WHERE l_partkey IN (SELECT partkey FROM target_parts)
GROUP BY l_partkey
),
small_orders AS (
SELECT l_extendedprice
FROM lineitem l
JOIN avg_quantity a ON l.l_partkey = a.l_partkey
WHERE l.l_quantity < 0.2 * a.avg_qty
)
SELECT SUM(l_extendedprice) / 7 AS avg_yearly_loss
FROM small_orders;
