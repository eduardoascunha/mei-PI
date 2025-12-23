select
	s_name,
	s_address,
	s_phone,
	sum(l_extendedprice * (1 - l_discount)) as total_revenue_lost
from
	supplier,
	lineitem l1,
	orders,
	nation
where
	s_suppkey = l1.l_suppkey
	and o_orderkey = l1.l_orderkey
	and o_orderstatus = 'F'
	and l1.l_receiptdate > l1.l_commitdate
	and exists (
		select
			1
		from
			lineitem l2
		where
			l2.l_orderkey = l1.l_orderkey
			and l2.l_suppkey <> l1.l_suppkey
			and l2.l_receiptdate <= l2.l_commitdate
	)
	and not exists (
		select
			1
		from
			lineitem l3
		where
			l3.l_orderkey = l1.l_orderkey
			and l3.l_suppkey <> l1.l_suppkey
			and l3.l_receiptdate > l3.l_commitdate
	)
	and s_nationkey = n_nationkey
	and n_name = 'ETHIOPIA'
group by
	s_name,
	s_address,
	s_phone
order by
	total_revenue_lost desc
limit 100;