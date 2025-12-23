select
o_orderkey,
o_orderdate,
o_shippriority,
sum(l_extendedprice * (1 - l_discount)) as revenue
from
customer
join orders on c_custkey = o_custkey
join lineitem on o_orderkey = l_orderkey
where
c_mktsegment = 'FURNITURE'
and o_orderdate < date '1995-03-27'
and l_shipdate > date '1995-03-27'
group by
o_orderkey,
o_orderdate,
o_shippriority
order by
revenue desc
limit 10;
