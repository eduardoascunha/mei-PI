select
	s_name,
	s_nationkey,
	l_orderkey,
	l_linenumber,
	l_shipdate,
	l_commitdate,
	l_receiptdate
from
	supplier,
	lineitem,
	orders,
	nation
where
	s_suppkey = l_suppkey
	and l_orderkey = o_orderkey
	and o_orderstatus = 'F'
	and l_receiptdate > l_commitdate
	and s_nationkey = n_nationkey
	and n_name = 'ETHIOPIA'
	and l_orderkey in (
		select
			l_orderkey
		from
			lineitem
		group by
			l_orderkey
		having
			count(distinct case when l_receiptdate > l_commitdate then l_suppkey end) = 1
			and count(distinct l_suppkey) > 1
	)
limit 100;