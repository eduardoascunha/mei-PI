select
	c_name,
	c_custkey,
	c_acctbal,
	c_phone,
	n_name,
	c_address,
	c_comment
from
	customer,
	orders,
	lineitem,
	nation
where
	c_custkey = o_custkey
	and l_orderkey = o_orderkey
	and o_orderdate >= date '1993-08-01'
	and o_orderdate < date '1993-08-01' + interval '3' month
	and l_returnflag = 'R'
	and c_nationkey = n_nationkey
group by
	c_name,
	c_custkey,
	c_acctbal,
	c_phone,
	n_name,
	c_address,
	c_comment
order by
	sum(l_extendedprice * (1 - l_discount)) desc
limit 20;