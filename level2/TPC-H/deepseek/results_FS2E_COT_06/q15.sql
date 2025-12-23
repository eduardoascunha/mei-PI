select
	s_suppkey,
	s_name,
	s_address,
	s_phone,
	total_revenue
from (
	select
		s.s_suppkey,
		s.s_name,
		s.s_address,
		s.s_phone,
		sum(l.l_extendedprice * (1 - l.l_discount)) as total_revenue,
		rank() over (order by sum(l.l_extendedprice * (1 - l.l_discount)) desc) as revenue_rank
	from
		supplier s,
		lineitem l,
		orders o
	where
		s.s_suppkey = l.l_suppkey
		and l.l_orderkey = o.o_orderkey
		and l.l_shipdate >= date '1997-01-01'
		and l.l_shipdate < date '1997-01-01' + interval '3' month
	group by
		s.s_suppkey, s.s_name, s.s_address, s.s_phone
) supplier_revenue
where
	revenue_rank = 1
order by
	s_suppkey;