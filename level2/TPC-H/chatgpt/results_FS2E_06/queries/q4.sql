select
o_orderpriority,
count(distinct o_orderkey) as order_count
from
orders o
join lineitem l on o.o_orderkey = l.l_orderkey
where
o.o_orderdate >= date '1997-01-01'
and o.o_orderdate < date '1997-01-01' + interval '3' month
and l.l_receiptdate > l.l_commitdate
group by
o_orderpriority
order by
o_orderpriority;
