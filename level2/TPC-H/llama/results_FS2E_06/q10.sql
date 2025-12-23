select
	c.c_name,
	c.c_address,
	n.n_name as nation,
	c.c_phone,
	c.c_acctbal,
	c.c_comment,
	sum(l.l_extendedprice * (1 - l.l_discount)) as revenue_lost
from
	customer c,
	orders o,
	lineitem l,
	nation n
where
	c.c_custkey = o.o_custkey
	and l.l_orderkey = o.o_orderkey
	and o.o_orderdate >= date '1993-08-01'
	and o.o_orderdate < date '1993-08-01' + interval '3 month'
	and l.l_returnflag = 'R'
	and c.c_nationkey = n.n_nationkey
group by
	c.c_name,
	c.c_address,
	n.n_name,
	c.c_phone,
	c.c_acctbal,
	c.c_comment
order by
	revenue_lost desc
limit 20;