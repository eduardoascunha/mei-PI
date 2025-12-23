select
	o_orderpriority,
	sum(l_extendedprice * (1 - l_discount)) as revenue
from
	orders,
	lineitem
where
	o_orderkey = l_orderkey
	and l_shipdate > date '1995-03-27'
	and o_orderdate < date '1995-03-27'
	and o_orderstatus = 'O'
	and c_mktsegment = 'FURNITURE'
	and c_custkey = o_custkey
group by
	o_orderpriority
order by
	revenue desc
limit 10;