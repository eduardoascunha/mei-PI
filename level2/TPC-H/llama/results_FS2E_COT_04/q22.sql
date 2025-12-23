select
	count(c_custkey) as cust_count,
	sum(c_acctbal) as acct_balance_sum
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
			o_orderdate >= (current_date - interval '7' year)
	);