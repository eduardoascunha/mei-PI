select
s_suppkey,
s_name,
s_acctbal,
s_address,
s_phone,
sum(l_extendedprice * (1 - l_discount)) as total_revenue
from
supplier,
lineitem
where
s_suppkey = l_suppkey
and l_shipdate >= date '1997-01-01'
and l_shipdate < date '1997-01-01' + interval '3' month
group by
s_suppkey,
s_name,
s_acctbal,
s_address,
s_phone
having
sum(l_extendedprice * (1 - l_discount)) = (
select
max(sub.total_revenue)
from
(
select
s_suppkey as suppkey,
sum(l_extendedprice * (1 - l_discount)) as total_revenue
from
supplier,
lineitem
where
s_suppkey = l_suppkey
and l_shipdate >= date '1997-01-01'
and l_shipdate < date '1997-01-01' + interval '3' month
group by
s_suppkey
) as sub
)
order by
s_suppkey;
