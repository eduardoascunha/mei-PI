select
	c_custkey,
	c_name,
	c_acctbal,
	substring(c_phone from 1 for 2) as country_code,
	c_phone,
	c_address,
	c_comment
from
	customer
where
	substring(c_phone from 1 for 2) in ('30', '31', '28', '21', '26', '33', '10')
	and c_acctbal > (select avg(c_acctbal) from customer where c_acctbal > 0)
	and not exists (
		select 1
		from orders
		where o_custkey = c_custkey
		and o_orderdate >= current_date - interval '7 years'
	)
order by
	c_acctbal desc;