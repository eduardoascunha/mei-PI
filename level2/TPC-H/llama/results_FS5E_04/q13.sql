select
	cust_cnt,
	count(*) as custdist
from
	(
		select
			c_custkey,
			count(o_orderkey) as cust_cnt
		from
			customer left outer join orders on
				c_custkey = o_custkey
				and o_comment not like '%unusual%accounts%'
		group by
			c_custkey
	) as c_orders
group by
	cust_cnt
order by
	custdist desc,
	cust_cnt;