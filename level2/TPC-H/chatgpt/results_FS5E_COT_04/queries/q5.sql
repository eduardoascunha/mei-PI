select
n_name,
sum(l_extendedprice * (1 - l_discount)) as revenue
from
lineitem,
orders,
customer,
supplier,
nation n1,
nation n2,
region
where
c_custkey = o_custkey
and l_orderkey = o_orderkey
and l_suppkey = s_suppkey
and c_nationkey = n2.n_nationkey
and s_nationkey = n1.n_nationkey
and n1.n_regionkey = r_regionkey
and r_name = 'EUROPE'
and l_shipdate >= date '1994-01-01'
and l_shipdate < date '1994-01-01' + interval '1' year
and n1.n_nationkey = n2.n_nationkey
group by
n_name
order by
revenue desc;
