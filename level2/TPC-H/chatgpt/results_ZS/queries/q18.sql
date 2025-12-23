SELECT
c.c_name,
c.c_custkey,
o.o_orderkey,
o.o_orderdate,
o.o_totalprice,
SUM(l.l_quantity) AS total_quantity
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY
c.c_name,
c.c_custkey,
o.o_orderkey,
o.o_orderdate,
o.o_totalprice
HAVING SUM(l.l_quantity) > 314
ORDER BY total_quantity DESC
LIMIT 100;
