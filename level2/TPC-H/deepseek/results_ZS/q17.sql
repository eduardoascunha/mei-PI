WITH avg_quantity AS (
    SELECT AVG(l_quantity) AS avg_qty
    FROM lineitem
    JOIN part ON l_partkey = p_partkey
    WHERE p_brand = 'Brand#23' AND p_container = 'SM CAN'
),
filtered_lineitems AS (
    SELECT l_extendedprice, l_quantity, l_discount, EXTRACT(YEAR FROM o_orderdate) AS order_year
    FROM lineitem
    JOIN orders ON l_orderkey = o_orderkey
    JOIN part ON l_partkey = p_partkey
    WHERE p_brand = 'Brand#23' AND p_container = 'SM CAN' AND l_quantity < 0.2 * (SELECT avg_qty FROM avg_quantity)
)
SELECT order_year, SUM(l_extendedprice * (1 - l_discount)) AS yearly_loss
FROM filtered_lineitems
GROUP BY order_year
ORDER BY order_year;