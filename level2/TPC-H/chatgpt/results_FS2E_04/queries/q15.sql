select
s.s_suppkey,
s.s_name,
sum(l.l_extendedprice * (1 - l.l_discount)) as total_revenue
from
supplier s
join lineitem l on s.s_suppkey = l.l_suppkey
where
l.l_shipdate >= date '1997-01-01'
and l.l_shipdate < date '1997-01-01' + interval '3' month
group by
s.s_suppkey,
s.s_name
having
sum(l.l_extendedprice * (1 - l.l_discount)) = (
select
max(rev)
from (
select
sum(l2.l_extendedprice * (1 - l2.l_discount)) as rev
from
supplier s2
join lineitem l2 on s2.s_suppkey = l2.l_suppkey
where
l2.l_shipdate >= date '1997-01-01'
and l2.l_shipdate < date '1997-01-01' + interval '3' month
group by
s2.s_suppkey
) x
)
order by
s.s_suppkey;
