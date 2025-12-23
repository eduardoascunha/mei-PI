select
	c_custkey,
	c_name,
	sum(l_extendedprice * (1 - l_discount)) as revenue,
	c_acctbal,
	n_name,
	c_address,
	c_phone,
	c_comment
from
	customer,
	orders,
	lineitem,
	nation
where
	c_custkey = o_custkey
	and l_orderkey = o_orderkey
	and o_orderdate >= date '1995-01-01'
	and o_orderdate < date '1995-01-01' + interval '1 year'
	and l_returnflag = 'R'
	and c_nationkey = n_nationkey
group by
	c_custkey,
	c_name,
	c_acctbal,
	c_phone,
	n_name,
	c_address,
	c_comment
having
	sum(l_extendedprice * (1 - l_discount)) > (
		select
			0.25 * sum(l_extendedprice * (1 - l_discount))
		from
			lineitem,
			orders
		where
			l_orderkey = o_orderkey
			and o_orderdate >= date '1995-01-01'
			and o_orderdate < date '1995-01-01' + interval '1 year'
			and l_returnflag = 'R'
	)
order by
	revenue desc;

-- The above query is not the correct solution. Let's rethink.

select
	count(*) as cust_count,
	avg(c_acctbal) as avg_acctbal
from
	customer
where
	substring(c_phone from 1 for 2) in ('30', '31', '28', '21', '26', '33', '10')
	and c_acctbal > (
		select
			avg(c_acctbal)
		from
			customer
		where
			c_acctbal > 0.00
	)
	and c_custkey not in (
		select
			o_custkey
		from
			orders
		where
			o_orderdate >= (current_date - interval '7 year')
	);