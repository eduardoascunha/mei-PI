select
	count(*) as cust_count,
	sum(c_acctbal) as tot_acctbal
from
	customer
where
	c_acctbal > (
		select
			avg(c_acctbal)
		from
			customer
		where
			c_acctbal > 0.00
	)
	and c_phone like any (array['30%', '31%', '28%', '21%', '26%', '33%', '10%'])
	and c_custkey not in (
		select
			o_custkey
		from
			orders
		where
			o_orderdate >= date '1995-01-01'
			and o_orderdate < date '1995-01-01' + interval '7' year
	);