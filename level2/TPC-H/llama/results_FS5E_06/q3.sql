select
	o_orderpriority,
	sum(l_extendedprice * (1 - l_discount)) as revenue
from
	orders,
	lineitem
where
	o_orderkey = l_orderkey
	and o_orderstatus = 'O'
	and l_shipdate > date '1995-03-27'
	and o_custkey in (
		select
			c_custkey
		from
			customer
		where
			c_mktsegment = 'FURNITURE'
	)
group by
	o_orderpriority
order by
	revenue desc
limit 10;