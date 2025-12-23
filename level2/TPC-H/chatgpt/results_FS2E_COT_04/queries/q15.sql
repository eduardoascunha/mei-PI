select
s.s_suppkey,
s.s_name,
sum(l.l_extendedprice * (1 - l.l_discount)) as total_revenue
from
supplier s,
lineitem l
where
s.s_suppkey = l.l_suppkey
and l.l_shipdate >= date '1997-01-01'
and l.l_shipdate < date '1997-01-01' + interval '3' month
group by
s.s_suppkey,
s.s_name
having
sum(l.l_extendedprice * (1 - l.l_discount)) = (
select
max(supplier_rev)
from
(
select
sum(l2.l_extendedprice * (1 - l2.l_discount)) as supplier_rev
from
lineitem l2
where
l2.l_shipdate >= date '1997-01-01'
and l2.l_shipdate < date '1997-01-01' + interval '3' month
group by
l2.l_suppkey
) as revs
)
order by
s.s_suppkey;
