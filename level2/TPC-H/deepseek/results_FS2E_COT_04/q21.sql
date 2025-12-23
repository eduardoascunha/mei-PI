select
	s_name,
	s_address,
	s_phone,
	s_acctbal,
	s_comment
from
	supplier,
	nation,
	lineitem l1,
	orders,
	(
		select
			l_orderkey
		from
			lineitem
		group by
			l_orderkey
		having
			count(distinct l_suppkey) > 1
	) multi_supplier
where
	s_suppkey = l1.l_suppkey
	and s_nationkey = n_nationkey
	and n_name = 'ETHIOPIA'
	and l1.l_orderkey = o_orderkey
	and o_orderstatus = 'F'
	and l1.l_orderkey = multi_supplier.l_orderkey
	and l1.l_receiptdate > l1.l_commitdate
	and not exists (
		select
			1
		from
			lineitem l2
		where
			l2.l_orderkey = l1.l_orderkey
			and l2.l_suppkey <> l1.l_suppkey
			and l2.l_receiptdate > l2.l_commitdate
	)
order by
	s_name
limit 100;