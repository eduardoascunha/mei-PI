select
	extract(year from o_orderdate) as o_year,
	p_type,
	n_name,
	sum(l_extendedprice * (1 - l_discount)) as volume
from
	part,
	supplier,
	lineitem,
	orders,
	nation,
	region
where
	p_partkey = l_partkey
	and s_suppkey = l_suppkey
	and l_orderkey = o_orderkey
	and o_custkey = c_custkey
	and c_nationkey = n_nationkey
	and n_regionkey = r_regionkey
	and r_name = 'AFRICA'
	and o_orderdate >= date '1995-01-01'
	and o_orderdate <= date '1996-12-31'
	and p_type = 'ECONOMY PLATED BRASS'
	and s_nationkey = n_nationkey
	and n_name = 'KENYA'
group by
	extract(year from o_orderdate),
	n_name,
	p_type
order by
	o_year,
	n_name,
	p_type;