with avgq as (
select avg(l_quantity) as avg_qty
from lineitem
join part on p_partkey = l_partkey
where p_brand = 'Brand#23'
and p_container = 'SM CAN'
)
select
coalesce(sum(l_extendedprice), 0) / 7.0 as avg_yearly_loss
from lineitem
join part on p_partkey = l_partkey
cross join avgq
where p_brand = 'Brand#23'
and p_container = 'SM CAN'
and l_quantity < 0.2 * avgq.avg_qty;
