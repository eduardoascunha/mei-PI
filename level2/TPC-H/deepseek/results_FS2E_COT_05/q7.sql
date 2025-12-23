select
	s_nation as supp_nation,
	c_nation as cust_nation,
	extract(year from l_shipdate) as l_year,
	sum(l_extendedprice * (1 - l_discount)) as revenue
from
	(
		select
			n1.n_name as s_nation,
			n2.n_name as c_nation,
			l_shipdate,
			l_extendedprice,
			l_discount
		from
			supplier,
			lineitem,
			orders,
			customer,
			nation n1,
			nation n2
		where
			s_suppkey = l_suppkey
			and l_orderkey = o_orderkey
			and o_custkey = c_custkey
			and s_nationkey = n1.n_nationkey
			and c_nationkey = n2.n_nationkey
			and (
				(n1.n_name = 'ARGENTINA' and n2.n_name = 'KENYA')
				or (n1.n_name = 'KENYA' and n2.n_name = 'ARGENTINA')
			)
			and l_shipdate between date '1995-01-01' and date '1996-12-31'
	) as shipping
group by
	supp_nation,
	cust_nation,
	l_year
order by
	supp_nation,
	cust_nation,
	l_year;