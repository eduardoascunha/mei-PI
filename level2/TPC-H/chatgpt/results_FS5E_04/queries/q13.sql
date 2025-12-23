select
order_count,
count(*) as customer_count
from (
select
c.c_custkey,
count(o.o_orderkey) filter (
where o.o_comment not like '%unusual%accounts%'
) as order_count
from
customer c
left join orders o on c.c_custkey = o.o_custkey
group by
c.c_custkey
) x
group by
order_count
order by
order_count;
