select
100.0 * sum(case when p.p_type like 'PROMO%' then l.l_extendedprice * (1 - l.l_discount) else 0 end)
/ sum(l.l_extendedprice * (1 - l.l_discount)) as promo_revenue_percentage
from lineitem l
join part p on l.l_partkey = p.p_partkey
where l.l_shipdate >= date '1996-04-01'
and l.l_shipdate < (date '1996-04-01' + interval '1 month');
