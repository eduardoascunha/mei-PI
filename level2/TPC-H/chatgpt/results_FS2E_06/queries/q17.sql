select
sum(l_extendedprice) / 7.0 * 0.2 as avg_yearly_loss
from
lineitem,
part
where
l_partkey = p_partkey
and p_brand = 'Brand#23'
and p_container = 'SM CAN'
and l_quantity < 0.2 * (
select
avg(l_quantity)
from
lineitem li,
part pa
where
li.l_partkey = pa.p_partkey
and pa.p_brand = 'Brand#23'
and pa.p_container = 'SM CAN'
);
