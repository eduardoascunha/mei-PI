select
	custsale.custcount,
	count(custsale.custkey) as custdist
from
	(
		select
			c_custkey as custkey,
			count(o_orderkey) as custcount
		from
			customer
		left outer join
			orders
		on
			c_custkey = o_custkey
			and o_comment not like '%unusual%accounts%'
		group by
			c_custkey
	) as custsale
group by
	custsale.custcount
order by
	custdist desc,
	custsale.custcount desc;