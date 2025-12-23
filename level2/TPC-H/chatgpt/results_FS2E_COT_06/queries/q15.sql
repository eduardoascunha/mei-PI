with supplier_revenue as (
select
l_suppkey as s_suppkey,
sum(l_extendedprice * (1 - l_discount)) as revenue
from
lineitem
where
l_shipdate >= date '1997-01-01'
and l_shipdate < date '1997-01-01' + interval '3' month
group by
l_suppkey
)
select
s.s_suppkey,
s.s_name,
s.s_address,
s.s_phone,
sr.revenue
from
supplier s
join supplier_revenue sr on s.s_suppkey = sr.s_suppkey
where
sr.revenue = (select max(revenue) from supplier_revenue)
order by
s.s_suppkey;
