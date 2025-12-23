SELECT n.n_name AS nation, EXTRACT(YEAR FROM o.o_orderdate) AS year, 
       SUM(l.l_extendedprice * (1 - l.l_discount) - ps.ps_supplycost * l.l_quantity) AS profit
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN part p ON l.l_partkey = p.p_partkey
WHERE p.p_name LIKE '%red%'
  AND l.l_linestatus = 'F'
GROUP BY n.n_name, EXTRACT(YEAR FROM o.o_orderdate)
ORDER BY n.n_name ASC, year DESC;