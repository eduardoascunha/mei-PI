select
	count(*) as numcust,
	sum(c_acctbal) as totacctbal
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
	and c_custkey not in (
		select
			o_custkey
		from
			orders
		where
			o_orderdate >= (current_date - interval '7' year)
	)
	and substr(c_phone, 1, 2) in ('30', '31', '28', '21', '26', '33', '10');