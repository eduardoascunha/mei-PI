select
cnt as ordercount,
count(*) as custdist
from
(
select
c_custkey,
count(o_orderkey) as cnt
from
customer left join orders on c_custkey = o_custkey
and o_comment not like '%unusual%accounts%'
group by
c_custkey
) as orders_per_customer
group by
cnt
order by
ordercount;
