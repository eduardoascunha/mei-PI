select
	s_name,
	s_suppkey,
	s_phone,
	s_acctbal,
	s_comment
from
	supplier,
	nation
where
	s_nationkey = n_nationkey
	and n_name = 'ETHIOPIA'
	and exists (
		select
			1
		from
			lineitem l1,
			orders,
			lineitem l2
		where
			l1.l_orderkey = o_orderkey
			and l2.l_orderkey = o_orderkey
			and l1.l_suppkey = s_suppkey
			and l1.l_receiptdate > l1.l_commitdate
			and l2.l_receiptdate <= l2.l_commitdate
			and o_orderstatus = 'F'
			and l1.l_orderkey in (
				select
					l_orderkey
				from
					lineitem
				group by
					l_orderkey
				having
					count(distinct l_suppkey) > 1
			)
	)
order by
	s_name
limit 100;