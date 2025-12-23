select
avg(l_quantity) as avg_qty,
avg(l_extendedprice) as avg_revenue_loss
from
lineitem,
part
where
p_partkey = l_partkey
and p_brand = 'Brand#23'
and p_container = 'SM CAN'
and l_quantity < (0.2 * (
select
avg(l_quantity)
from
lineitem
join part on p_partkey = l_partkey
where
p_brand = 'Brand#23'
and p_container = 'SM CAN'
))
;
