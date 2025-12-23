select
	count(c_custkey) as customer_count,
	coalesce(order_count, 0) as order_count
from
	customer
left join (
	select
		o_custkey,
		count(*) as order_count
	from
		orders
	where
		o_comment not like '%unusual%accounts%'
	group by
		o_custkey
) as cust_orders on c_custkey = cust_orders.o_custkey
group by
	coalesce(order_count, 0)
order by
	order_count;