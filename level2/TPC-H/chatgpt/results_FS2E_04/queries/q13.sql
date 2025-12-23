select
coalesce(o.cnt, 0) as order_count,
count(*) as customer_count
from (
select
c.c_custkey,
count(o.o_orderkey) as cnt
from
customer c
left join orders o
on c.c_custkey = o.o_custkey
and o.o_comment not like '%unusual%accounts%'
group by
c.c_custkey
) o
group by
coalesce(o.cnt, 0)
order by
order_count;
