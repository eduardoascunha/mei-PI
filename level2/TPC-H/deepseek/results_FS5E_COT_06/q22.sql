select
	substr(c_phone, 1, 2) as cntrycode,
	count(*) as numcust,
	sum(c_acctbal) as totacctbal
from
	customer
where
	substr(c_phone, 1, 2) in ('30', '31', '28', '21', '26', '33', '10')
	and c_acctbal > (
		select
			avg(c_acctbal)
		from
			customer
		where
			c_acctbal > 0.00
			and substr(c_phone, 1, 2) in ('30', '31', '28', '21', '26', '33', '10')
	)
	and not exists (
		select
			*
		from
			orders
		where
			o_custkey = c_custkey
			and o_orderdate >= date_add(current_date, interval -7 year)
	)
group by
	substr(c_phone, 1, 2)
order by
	substr(c_phone, 1, 2);