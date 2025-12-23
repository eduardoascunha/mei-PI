select
	o_orderpriority,
	sum(l_extendedprice * (1 - l_discount)) as revenue
from
	orders,
	lineitem
where
	o_orderkey = l_orderkey
	and o_orderdate < date '1995-03-27'
	and l_shipdate > date '1995-03-27'
	and c_mktsegment = 'FURNITURE'
	and o_custkey = c_custkey
group by
	o_orderpriority
order by
	revenue desc
limit 10;