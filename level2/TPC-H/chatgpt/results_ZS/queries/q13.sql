select
  order_count,
  count(*) as customer_count
from (
  select
    c.c_custkey,
    count(o.o_orderkey) as order_count
  from customer c
  left join orders o
    on c.c_custkey = o.o_custkey
   and o.o_comment not ilike '%unusual%accounts%'
  group by c.c_custkey
) t
group by order_count
order by order_count;