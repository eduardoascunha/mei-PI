select num_orders, count(*) as cust_count
from (
select c_custkey,
coalesce(count(o_orderkey), 0) as num_orders
from customer
left join orders
on c_custkey = o_custkey
and o_comment not like '%unusual accounts%'
group by c_custkey
) t
group by num_orders
order by num_orders;
