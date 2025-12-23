WITH nation_supp AS (
SELECT s_suppkey
FROM supplier
JOIN nation ON supplier.s_nationkey = nation.n_nationkey
WHERE nation.n_name = 'UNITED STATES'
),
part_values AS (
SELECT ps_partkey AS partkey,
SUM(ps_availqty * ps_supplycost) AS value
FROM partsupp
WHERE ps_suppkey IN (SELECT s_suppkey FROM nation_supp)
GROUP BY ps_partkey
),
total_value AS (
SELECT SUM(value) AS tot FROM part_values
)
SELECT pv.partkey AS p_partkey,
pv.value AS part_value
FROM part_values pv, total_value tv
WHERE pv.value > tv.tot * 0.0001000000
ORDER BY pv.value DESC;
