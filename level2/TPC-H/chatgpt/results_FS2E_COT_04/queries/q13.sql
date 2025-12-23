select
c_count,
count(*) as custdist
from
(
select
c_custkey,
count(o_orderkey) as c_count
from
customer left join orders
on c_custkey = o_custkey
and o_comment not like '%unusual accounts%'
group by
c_custkey
) as cust_orders
group by
c_count
order by
c_count;
