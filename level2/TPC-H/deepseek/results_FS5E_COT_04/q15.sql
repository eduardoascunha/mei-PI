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
			rank() over (order by sum(l_extendedprice * (1 - l_discount)) desc) as rnk
		from
			supplier,
			lineitem,
			orders,
			nation
		where
			s_suppkey = l_suppkey
			and l_orderkey = o_orderkey
			and s_nationkey = n_nationkey
			and o_orderdate >= date '1997-01-01'
			and o_orderdate < date '1997-01-01' + interval '3' month
		group by
			s_suppkey,
			s_name,
			s_address,
			s_phone
	) revenue_rank
where
	rnk = 1
order by
	s_suppkey;