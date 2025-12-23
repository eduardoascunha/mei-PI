select
order_count,
count(*) as customer_count
from (
select
o_custkey,
count(o_orderkey) as order_count
from
orders
where
o_comment not like '%unusual%accounts%'
group by
o_custkey
union all
select
c_custkey,
0 as order_count
from
customer
where
not exists (
select
1
from
orders
where
o_custkey = c_custkey
)
) as order_counts
group by
order_count
order by
order_count;
