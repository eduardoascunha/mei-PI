select
	n1.n_name as supp_nation,
	n2.n_name as cust_nation,
	extract(year from l_shipdate) as l_year,
	sum(l_extendedprice * (1 - l_discount)) as revenue
from
	customer,
	orders,
	lineitem,
	supplier,
	nation n1,
	nation n2
where
	c_custkey = o_custkey
	and o_orderkey = l_orderkey
	and l_suppkey = s_suppkey
	and c_nationkey = n2.n_nationkey
	and s_nationkey = n1.n_nationkey
	and (
		(n1.n_name = 'ARGENTINA' and n2.n_name = 'KENYA')
		or (n1.n_name = 'KENYA' and n2.n_name = 'ARGENTINA')
	)
	and l_shipdate between date '1995-01-01' and date '1996-12-31'
group by
	n1.n_name,
	n2.n_name,
	extract(year from l_shipdate)
order by
	n1.n_name,
	n2.n_name,
	l_year;