select
s_suppkey,
s_name,
s_address,
s_phone,
total_revenue
from (
select
s.s_suppkey,
s.s_name,
s.s_address,
s.s_phone,
sum(l.l_extendedprice * (1 - l.l_discount)) as total_revenue,
max(sum(l.l_extendedprice * (1 - l.l_discount))) over () as max_revenue
from
supplier s
join lineitem l on s.s_suppkey = l.l_suppkey
where
l.l_shipdate >= date '1997-01-01'
and l.l_shipdate < date '1997-01-01' + interval '3' month
group by
s.s_suppkey,
s.s_name,
s.s_address,
s.s_phone
) t
where
total_revenue = max_revenue
order by
s_suppkey;
