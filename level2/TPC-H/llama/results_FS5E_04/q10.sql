select
	c_name,
	c_custkey,
	o_orderkey,
	o_orderdate,
	o_totalprice,
	sum(l_quantity) as sum_qty,
	sum(l_extendedprice * (1 - l_discount)) as revenue,
	l_returnflag,
	l_linestatus
from
	customer,
	orders,
	lineitem
where
	c_custkey = o_custkey
	and l_orderkey = o_orderkey
	and o_orderdate >= date '1993-08-01'
	and o_orderdate < date '1993-08-01' + interval '3' month
	and l_returnflag = 'R'
group by
	c_name,
	c_custkey,
	o_orderkey,
	o_orderdate,
	o_totalprice,
	l_returnflag,
	l_linestatus
order by
	revenue desc
limit 20;