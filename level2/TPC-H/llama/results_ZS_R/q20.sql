WITH part_filter AS (
  SELECT p_partkey, p_name 
  FROM part 
  WHERE p_name LIKE 'brown%'
),
supplier_nation AS (
  SELECT s_suppkey 
  FROM supplier 
  JOIN nation ON s_nationkey = n_nationkey 
  WHERE n_name = 'SAUDI ARABIA'
),
annual_part_supp AS (
  SELECT ps_suppkey, ps_partkey, SUM(l_quantity) AS total_shipped 
  FROM lineitem 
  JOIN orders ON l_orderkey = o_orderkey 
  JOIN partsupp ON l_partkey = ps_partkey AND l_suppkey = ps_suppkey 
  WHERE o_orderdate >= '1994-01-01' AND o_orderdate < '1995-01-01' 
  GROUP BY ps_suppkey, ps_partkey
),
excess_parts AS (
  SELECT ps.ps_suppkey, ps.ps_partkey, ps.ps_availqty 
  FROM partsupp ps 
  JOIN annual_part_supp aps ON ps.ps_suppkey = aps.ps_suppkey AND ps.ps_partkey = aps.ps_partkey 
  JOIN part_filter pf ON ps.ps_partkey = pf.p_partkey 
  WHERE ps.ps_availqty > 0.5 * aps.total_shipped
)
SELECT s.s_name, p.p_name, ps.ps_availqty, ps.ps_supplycost 
FROM excess_parts ep 
JOIN supplier_nation sn ON ep.ps_suppkey = sn.s_suppkey 
JOIN supplier s ON ep.ps_suppkey = s.s_suppkey 
JOIN part p ON ep.ps_partkey = p.p_partkey 
ORDER BY s.s_name, p.p_name;