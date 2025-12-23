select
l_shipmode,
sum(case when o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH' then 1 else 0 end) as high_line_count,
sum(case when not (o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH') then 1 else 0 end) as low_line_count
from
lineitem,
orders
where
l_shipmode in ('FOB','MAIL')
and l_receiptdate >= date '1996-01-01'
and l_receiptdate < date '1996-01-01' + interval '1' year
and l_receiptdate > l_commitdate
and l_shipdate < l_commitdate
and l_orderkey = o_orderkey
group by
l_shipmode
order by
l_shipmode;
