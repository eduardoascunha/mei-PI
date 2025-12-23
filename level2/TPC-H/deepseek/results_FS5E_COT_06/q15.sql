select
	s_suppkey,
	s_name,
	s_address,
	s_phone,
	total_revenue
from
	(
		select
			s_suppkey,
			s_name,
			s_address,
			s_phone,
			sum(l_extendedprice * (1 - l_discount)) as total_revenue,
			rank() over (order by sum(l_extendedprice * (1 - l_discount)) desc) as revenue_rank
		from
			supplier,
			lineitem,
			orders,
			nation
		where
			s_suppkey = l_suppkey
			and l_orderkey = o_orderkey
			and s_nationkey = n_nationkey
			and l_shipdate >= date '1997-01-01'
			and l_shipdate < date '1997-01-01' + interval '3' month
		group by
			s_suppkey,
			s_name,
			s_address,
			s_phone
	) as supplier_revenue
where
	revenue_rank = 1
order by
	s_suppkey;