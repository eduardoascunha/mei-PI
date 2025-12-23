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
sum(li.l_extendedprice * (1 - li.l_discount)) as rev
from
supplier su
join lineitem li on su.s_suppkey = li.l_suppkey
where
li.l_shipdate >= date '1997-01-01'
and li.l_shipdate < date '1997-01-01' + interval '3' month
group by
su.s_suppkey
) t
)
order by
s.s_suppkey;
