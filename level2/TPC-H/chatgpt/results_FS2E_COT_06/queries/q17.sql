select
sum(l_extendedprice) / 7.0 as avg_yearly
from
lineitem,
part
where
p_partkey = l_partkey
and p_brand = 'Brand#23'
and p_container = 'SM CAN'
and l_quantity < 0.2 * (
select avg(li.l_quantity)
from lineitem li, part p
where p.p_partkey = li.l_partkey
and p.p_brand = 'Brand#23'
and p.p_container = 'SM CAN'
);
