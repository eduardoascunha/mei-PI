select
o.o_orderkey,
o.o_orderdate,
o.o_shippriority,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from customer c
join orders o on c.c_custkey = o.o_custkey
join lineitem l on o.o_orderkey = l.l_orderkey
where c.c_mktsegment = 'FURNITURE'
and o.o_orderdate < date '1995-03-27'
and l.l_shipdate > date '1995-03-27'
group by o.o_orderkey, o.o_orderdate, o.o_shippriority
order by revenue desc
fetch first 10 rows only;
