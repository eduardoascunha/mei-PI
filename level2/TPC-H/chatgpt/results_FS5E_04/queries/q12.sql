select
l_shipmode,
sum(case when o_orderpriority in ('1-URGENT','2-HIGH') then 1 else 0 end) as high_priority_late,
sum(case when o_orderpriority not in ('1-URGENT','2-HIGH') then 1 else 0 end) as other_priority_late
from
lineitem
join orders on l_orderkey = o_orderkey
where
l_shipmode in ('FOB','MAIL')
and l_receiptdate >= date '1996-01-01'
and l_receiptdate < date '1996-01-01' + interval '1' year
and l_shipdate < l_commitdate
and l_receiptdate > l_commitdate
group by
l_shipmode
order by
l_shipmode;
