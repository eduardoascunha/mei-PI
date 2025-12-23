select
o_orderkey,
sum(l_extendedprice * (1 - l_discount)) as revenue,
o_orderdate,
o_shippriority
from
customer,
orders,
lineitem
where
c_custkey = o_custkey
and o_orderkey = l_orderkey
and c_mktsegment = 'FURNITURE'
and o_orderdate < date '1995-03-27'
and l_shipdate > date '1995-03-27'
group by
o_orderkey,
o_orderdate,
o_shippriority
order by
revenue desc,
o_orderdate
limit 10;
