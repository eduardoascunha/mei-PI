select
o_orderpriority,
count(distinct o_orderkey) as order_count
from
orders,
lineitem
where
o_orderkey = l_orderkey
and o_orderdate >= date '1997-01-01'
and o_orderdate < date '1997-01-01' + interval '3' month
and l_receiptdate > l_commitdate
group by
o_orderpriority
order by
o_orderpriority;
