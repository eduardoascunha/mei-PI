select
n.n_name,
sum(l_extendedprice * (1 - l_discount)) as revenue
from
region r
join nation n on n.n_regionkey = r.r_regionkey
join customer c on c.c_nationkey = n.n_nationkey
join orders o on o.o_custkey = c.c_custkey
join lineitem l on l.l_orderkey = o.o_orderkey
join supplier s on s.s_suppkey = l.l_suppkey
join nation n2 on n2.n_nationkey = s.s_nationkey
where
r.r_name = 'EUROPE'
and n.n_nationkey = n2.n_nationkey
and o.o_orderdate >= date '1994-01-01'
and o.o_orderdate < date '1994-01-01' + interval '1' year
group by
n.n_name
order by
revenue desc;
