select
	s_name,
	s_suppkey,
	s_phone,
	s_acctbal,
	n_name
from
	supplier,
	nation
where
	s_nationkey = n_nationkey
	and n_name = 'ETHIOPIA'
	and exists (
		select
			*
		from
			lineitem l1,
			orders
		where
			l1.l_suppkey = s_suppkey
			and o_orderkey = l1.l_orderkey
			and o_orderstatus = 'F'
			and l1.l_receiptdate > l1.l_commitdate
			and exists (
				select
					*
				from
					lineitem l2
				where
					l2.l_orderkey = l1.l_orderkey
					and l2.l_suppkey <> l1.l_suppkey
			)
			and not exists (
				select
					*
				from
					lineitem l3
				where
					l3.l_orderkey = l1.l_orderkey
					and l3.l_suppkey <> l1.l_suppkey
					and l3.l_receiptdate > l3.l_commitdate
			)
	)
order by
	s_name
limit 100;