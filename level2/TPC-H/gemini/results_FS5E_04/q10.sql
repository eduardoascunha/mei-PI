select
	c_name,
	c_address,
	n_name,
	c_phone,
	c_acctbal,
	c_comment,
	sum(l_extendedprice * (1 - l_discount)) as revenue_lost
from
	customer,
	orders,
	lineitem,
	nation
where
	c_custkey = o_custkey
	and o_orderkey = l_orderkey
	and c_nationkey = n_nationkey
	and l_returnflag = 'R'
	and o_orderdate >= date '1993-08-01'
	and o_orderdate < date '1993-08-01' + interval '3' month
group by
	c_custkey,
	c_name,
	c_address,
	c_phone,
	c_acctbal,
	n_name,
	c_comment
order by
	revenue_lost desc
limit 20;