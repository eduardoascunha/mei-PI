select
	n_name,
	extract(year from o_orderdate) as o_year,
	sum((l_extendedprice * (1 - l_discount)) - (ps_supplycost * l_quantity)) as profit
from
	part,
	supplier,
	lineitem,
	orders,
	partsupp,
	nation
where
	s_suppkey = l_suppkey
	and ps_suppkey = l_suppkey
	and ps_partkey = l_partkey
	and p_partkey = l_partkey
	and o_orderkey = l_orderkey
	and s_nationkey = n_nationkey
	and p_name like '%red%'
group by
	n_name,
	o_year
order by
	n_name,
	o_year desc;