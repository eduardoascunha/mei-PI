select
l.l_shipmode,
sum(case when o.o_orderpriority in ('1-URGENT','2-HIGH') then 1 else 0 end) as high_line_count,
sum(case when o.o_orderpriority not in ('1-URGENT','2-HIGH') then 1 else 0 end) as low_line_count
from lineitem l
join orders o on l.l_orderkey = o.o_orderkey
where l.l_shipmode in ('FOB','MAIL')
and l.l_shipdate < l.l_commitdate
and l.l_receiptdate > l.l_commitdate
and l.l_receiptdate >= date '1996-01-01'
and l.l_receiptdate < date '1996-01-01' + interval '1 year'
group by l.l_shipmode
order by l.l_shipmode;
