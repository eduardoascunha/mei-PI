select
sum(l_extendedprice) / 7.0 as avg_yearly_loss
from
lineitem,
part
where
p_partkey = l_partkey
and p_brand = 'Brand#23'
and p_container = 'SM CAN'
and l_quantity < (
select
0.2 * avg(l2.l_quantity)
from
lineitem l2
join part p2 on p2.p_partkey = l2.l_partkey
where
p2.p_brand = 'Brand#23'
and p2.p_container = 'SM CAN'
);
