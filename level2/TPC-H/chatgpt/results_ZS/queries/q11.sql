SELECT
ps.ps_partkey AS partkey,
SUM(ps.ps_supplycost * ps.ps_availqty) AS part_value
FROM partsupp ps
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE n.n_name = 'UNITED STATES'
GROUP BY ps.ps_partkey
HAVING SUM(ps.ps_supplycost * ps.ps_availqty) >
0.0001000000 * (
SELECT SUM(ps2.ps_supplycost * ps2.ps_availqty)
FROM partsupp ps2
JOIN supplier s2 ON ps2.ps_suppkey = s2.s_suppkey
JOIN nation n2 ON s2.s_nationkey = n2.n_nationkey
WHERE n2.n_name = 'UNITED STATES'
)
ORDER BY part_value DESC;
