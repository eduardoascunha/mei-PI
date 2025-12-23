select
	o_count,
	count(*) as custdist
from
	(
		select
			c_custkey,
			count(o_orderkey) as o_count
		from
			customer left outer join orders on
				c_custkey = o_custkey
				and o_comment not like '%unusual%accounts%'
		group by
			c_custkey
	) as c_orders
group by
	o_count
order by
	custdist desc,
	o_count desc;