select
    n_name as nation,
    sum(l_extendedprice * (1 - l_discount)) as revenue
from
    lineitem,
    orders,
    customer,
    supplier,
    nation,
    region
where
    l_orderkey = o_orderkey
    and o_custkey = c_custkey
    and l_suppkey = s_suppkey
    and c_nationkey = n_nationkey
    and s_nationkey = n_nationkey
    and n_regionkey = r_regionkey
    and r_name = 'EUROPE'
    and o_orderdate >= date '1994-01-01'
    and o_orderdate < date '1994-01-01' + interval '1' year
group by
    n_name
order by
    revenue desc;