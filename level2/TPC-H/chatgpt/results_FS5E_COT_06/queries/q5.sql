select
n.n_name as nation,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from
lineitem l,
orders o,
customer c,
supplier s,
nation n,
region r
where
l.l_orderkey = o.o_orderkey
and o.o_custkey = c.c_custkey
and l.l_suppkey = s.s_suppkey
and c.c_nationkey = n.n_nationkey
and s.s_nationkey = n.n_nationkey
and n.n_regionkey = r.r_regionkey
and r.r_name = 'EUROPE'
and o.o_orderdate >= date '1994-01-01'
and o.o_orderdate < date '1994-01-01' + interval '1' year
group by
n.n_name
order by
revenue desc;
