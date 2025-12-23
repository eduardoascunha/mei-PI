select
n.n_name as nation,
sum(l_extendedprice * (1 - l_discount)) as revenue
from
supplier,
customer,
lineitem,
orders,
nation n,
region r
where
s_suppkey = l_suppkey
and o_orderkey = l_orderkey
and c_custkey = o_custkey
and s_nationkey = n.n_nationkey
and c_nationkey = n.n_nationkey
and n.n_regionkey = r.r_regionkey
and r.r_name = 'EUROPE'
and o_orderdate between date '1994-01-01' and date '1994-12-31'
group by
n.n_name
order by
revenue desc;
