select
o_orderpriority,
count(distinct l_orderkey) as order_count
from
orders,
lineitem
where
o_orderkey = l_orderkey
and l_receiptdate > l_commitdate
and o_orderdate >= date '1997-01-01'
and o_orderdate < date '1997-01-01' + interval '3' month
group by
o_orderpriority
order by
o_orderpriority;
