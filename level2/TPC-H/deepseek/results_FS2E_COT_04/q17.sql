select
    sum(l_extendedprice) / 7 as avg_yearly_loss
from
    lineitem,
    part
where
    l_partkey = p_partkey
    and p_brand = 'Brand#23'
    and p_container = 'SM CAN'
    and l_quantity < 0.2 * (
        select avg(l_quantity)
        from lineitem, part
        where l_partkey = p_partkey
        and p_brand = 'Brand#23'
        and p_container = 'SM CAN'
    );