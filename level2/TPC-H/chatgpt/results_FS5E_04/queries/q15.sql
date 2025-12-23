select
s_suppkey,
s_name,
s_address,
s_phone,
s_acctbal,
total_revenue
from (
select
s_suppkey,
s_name,
s_address,
s_phone,
s_acctbal,
sum(l_extendedprice * (1 - l_discount)) as total_revenue
from
supplier
join lineitem on s_suppkey = l_suppkey
where
l_shipdate >= date '1997-01-01'
and l_shipdate < date '1997-01-01' + interval '3' month
group by
s_suppkey,
s_name,
s_address,
s_phone,
s_acctbal
) r
where
total_revenue = (
select
max(sum_rev)
from (
select
sum(l_extendedprice * (1 - l_discount)) as sum_rev
from
supplier
join lineitem on s_suppkey = l_suppkey
where
l_shipdate >= date '1997-01-01'
and l_shipdate < date '1997-01-01' + interval '3' month
group by
s_suppkey
) x
)
order by
s_suppkey;
