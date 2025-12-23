with avg_q as (
select avg(l.l_quantity) as avg_q
from lineitem l
join part p on p.p_partkey = l.l_partkey
where p.p_brand = 'Brand#23'
and p.p_container = 'SM CAN'
)
select
coalesce(sum(l.l_extendedprice),0) / 7.0 as avg_yearly_loss
from lineitem l
join part p on p.p_partkey = l.l_partkey
cross join avg_q
where p.p_brand = 'Brand#23'
and p.p_container = 'SM CAN'
and l.l_quantity < avg_q.avg_q * 0.2;
