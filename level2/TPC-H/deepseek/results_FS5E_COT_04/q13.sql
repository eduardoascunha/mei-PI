select
	count_orders,
	count(*) as cust_count
from
	(
		select
			c_custkey,
			count(o_orderkey) as count_orders
		from
			customer
			left outer join orders on
				c_custkey = o_custkey
				and o_comment not like '%unusual%accounts%'
		group by
			c_custkey
	) as cust_orders
group by
	count_orders
order by
	count_orders;