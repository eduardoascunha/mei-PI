select
l_orderkey,
sum(l_extendedprice * (1 - l_discount)) as revenue,
o_orderdate,
o_shippriority
from
customer c
join orders o on c.c_custkey = o.o_custkey
join lineitem l on o.o_orderkey = l.l_orderkey
where
c.c_mktsegment = 'FURNITURE'
and o.o_orderdate < date '1995-03-27'
and l_shipdate > date '1995-03-27'
group by
l_orderkey,
o_orderdate,
o_shippriority
order by
revenue desc
limit 10;
