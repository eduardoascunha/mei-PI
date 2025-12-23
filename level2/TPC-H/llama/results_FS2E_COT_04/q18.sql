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
	o_orderkey = l_orderkey
	and c_custkey = o_custkey
group by
	c_name,
	c_custkey,
	o_orderkey,
	o_orderdate,
	o_totalprice
having
	sum(l_quantity) > 314
order by
	o_totalprice desc,
	o_orderdate
limit 100;