select
l_shipmode,
case
when o_orderpriority in ('1-URGENT','2-HIGH') then 'URGENT/HIGH'
else 'OTHER'
end as priority_group,
count(*) as late_lineitems
from
lineitem
join orders on l_orderkey = o_orderkey
where
l_shipmode in ('FOB','MAIL')
and l_receiptdate >= date '1996-01-01'
and l_receiptdate < date '1996-01-01' + interval '1' year
and l_receiptdate > l_commitdate
and l_shipdate < l_commitdate
group by
l_shipmode,
case
when o_orderpriority in ('1-URGENT','2-HIGH') then 'URGENT/HIGH'
else 'OTHER'
end
order by
l_shipmode,
priority_group;
