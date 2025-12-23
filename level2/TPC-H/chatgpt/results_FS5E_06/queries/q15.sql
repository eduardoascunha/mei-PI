select
s_suppkey,
s_name,
sum(l_extendedprice * (1 - l_discount)) as total_revenue
from
supplier
join lineitem on s_suppkey = l_suppkey
where
l_shipdate >= date '1997-01-01'
and l_shipdate < date '1997-01-01' + interval '3' month
group by
s_suppkey,
s_name
having
sum(l_extendedprice * (1 - l_discount)) = (
select
max(supplier_revenue)
from (
select
sum(l_extendedprice * (1 - l_discount)) as supplier_revenue
from
supplier
join lineitem on s_suppkey = l_suppkey
where
l_shipdate >= date '1997-01-01'
and l_shipdate < date '1997-01-01' + interval '3' month
group by
s_suppkey
) t
)
order by
s_suppkey;
