select
	custsale.cntr as cust_cnt,
	count(custsale.c_custkey) as custdist
from (
	select
		c.c_custkey,
		count(o.o_orderkey) as cntr
	from
		customer c
	left join orders o on c.c_custkey = o.o_custkey
		and o.o_comment not like '%unusual%accounts%'
	group by
		c.c_custkey
) as custsale
group by
	custsale.cntr
order by
	custdist desc,
	cust_cnt desc;