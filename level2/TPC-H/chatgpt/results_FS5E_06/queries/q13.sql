select
ord_cnt,
count(*) as num_customers
from (
select
c.c_custkey,
count(o.o_orderkey) as ord_cnt
from
customer c
left join orders o
on c.c_custkey = o.o_custkey
and o.o_comment not like '%unusual%accounts%'
group by
c.c_custkey
) x
group by
ord_cnt
order by
ord_cnt;
