select
	sn.n_name as supp_nation,
	cn.n_name as cust_nation,
	extract(year from l_shipdate) as l_year,
	sum(l_extendedprice * (1 - l_discount)) as revenue
from
	supplier,
	lineitem,
	orders,
	customer,
	nation sn,
	nation cn
where
	s_suppkey = l_suppkey
	and o_orderkey = l_orderkey
	and c_custkey = o_custkey
	and s_nationkey = sn.n_nationkey
	and c_nationkey = cn.n_nationkey
	and (
		(sn.n_name = 'ARGENTINA' and cn.n_name = 'KENYA')
		or (sn.n_name = 'KENYA' and cn.n_name = 'ARGENTINA')
	)
	and l_shipdate between date '1995-01-01' and date '1996-12-31'
group by
	sn.n_name,
	cn.n_name,
	extract(year from l_shipdate)
order by
	supp_nation,
	cust_nation,
	l_year;