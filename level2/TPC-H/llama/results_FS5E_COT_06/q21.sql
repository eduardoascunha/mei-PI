select
	s_name,
	s_address
from
	supplier,
	nation
where
	s_suppkey in (
		select
			l_suppkey
		from
			lineitem
		where
			l_orderkey in (
				select
					o_orderkey
				from
					orders
				where
					o_orderstatus = 'F'
			)
			and l_commitdate < l_receiptdate
			and l_orderkey in (
				select
					l2.l_orderkey
				from
					lineitem l2
				where
					l2.l_orderkey = l_orderkey
					and l2.l_commitdate < l2.l_receiptdate
					and l2.l_suppkey <> l_suppkey
			)
			and l_suppkey in (
				select
					s_suppkey
				from
					supplier,
					nation
				where
					s_nationkey = n_nationkey
					and n_name = 'ETHIOPIA'
			)
			group by
				l_suppkey,
				l_orderkey
			having
				count(*) = 1
	)
	and s_nationkey = n_nationkey
	and n_name = 'ETHIOPIA'
order by
	s_name
limit 100;