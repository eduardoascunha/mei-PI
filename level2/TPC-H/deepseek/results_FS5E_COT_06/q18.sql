select
	c_name,
	c_custkey,
	o_orderkey,
	o_orderdate,
	o_totalprice,
	sum(l_quantity) as total_quantity
from
	customer,
	orders,
	lineitem
where
	c_custkey = o_custkey
	and o_orderkey = l_orderkey
group by
	c_name,
	c_custkey,
	o_orderkey,
	o_orderdate,
	o_totalprice
having
	sum(l_quantity) > 314
order by
	total_quantity desc,
	o_orderdate
limit 100;