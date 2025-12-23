select
	c_name,
	c_address,
	n_name as c_nation,
	c_phone,
	c_acctbal,
	c_comment,
	sum(l_extendedprice * (1 - l_discount)) as revenue
from
	customer,
	orders,
	lineitem,
	nation
where
	c_custkey = o_custkey
	and l_orderkey = o_orderkey
	and o_orderdate >= date '1993-08-01'
	and o_orderdate < date '1993-08-01' + interval '3 month'
	and l_returnflag = 'R'
	and c_nationkey = n_nationkey
group by
	c_name,
	c_address,
	c_nation,
	c_phone,
	c_acctbal,
	c_comment
order by
	revenue desc
limit 20;