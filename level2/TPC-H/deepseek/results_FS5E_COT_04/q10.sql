select
	c_custkey,
	c_name,
	sum(l_extendedprice * (1 - l_discount)) as revenue_loss
from
	customer,
	orders,
	lineitem,
	nation
where
	c_custkey = o_custkey
	and l_orderkey = o_orderkey
	and l_returnflag = 'R'
	and c_nationkey = n_nationkey
	and o_orderdate >= date '1993-08-01'
	and o_orderdate < date '1993-08-01' + interval '3' month
group by
	c_custkey,
	c_name,
	c_address,
	n_name,
	c_phone,
	c_acctbal,
	c_comment
order by
	revenue_loss desc
limit 20;