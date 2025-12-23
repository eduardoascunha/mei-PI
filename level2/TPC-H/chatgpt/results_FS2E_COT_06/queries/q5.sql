select
n.n_name as nation,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from
region r,
nation n,
supplier s,
lineitem l,
orders o,
customer c
where
r.r_name = 'EUROPE'
and r.r_regionkey = n.n_regionkey
and n.n_nationkey = s.s_nationkey
and s.s_suppkey = l.l_suppkey
and l.l_orderkey = o.o_orderkey
and o.o_custkey = c.c_custkey
and c.c_nationkey = n.n_nationkey
and l.l_shipdate between date '1994-01-01' and date '1994-12-31'
group by
n.n_name
order by
revenue desc;
