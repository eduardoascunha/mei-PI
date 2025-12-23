select
o_orderpriority,
count(*) as order_count
from (
select distinct o.o_orderkey, o.o_orderpriority
from orders o
join lineitem l on l.l_orderkey = o.o_orderkey
where o.o_orderdate >= date '1997-01-01'
and o.o_orderdate < date '1997-01-01' + interval '3' month
and l.l_receiptdate > l.l_commitdate
) q
group by o_orderpriority
order by o_orderpriority;
