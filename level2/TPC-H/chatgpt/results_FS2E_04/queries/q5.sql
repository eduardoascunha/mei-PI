select
n.n_name as nation,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from
region r
join nation n on n.n_regionkey = r.r_regionkey
join customer c on c.c_nationkey = n.n_nationkey
join orders o on o.o_custkey = c.c_custkey
join lineitem l on l.l_orderkey = o.o_orderkey
join supplier s on s.s_suppkey = l.l_suppkey
where
r.r_name = 'EUROPE'
and s.s_nationkey = n.n_nationkey
and o.o_orderdate >= date '1994-01-01'
and o.o_orderdate < date '1995-01-01'
group by
n.n_name
order by
revenue desc
