with avg_qty as (
  select 
    avg(l_quantity) as avg_quantity
  from 
    lineitem, 
    part
  where 
    l_partkey = p_partkey 
    and p_brand = 'Brand#23' 
    and p_container = 'SM CAN'
)
select 
  avg(l_extendedprice) as avg_yearly_loss
from 
  lineitem, 
  part, 
  avg_qty
where 
  l_partkey = p_partkey 
  and p_brand = 'Brand#23' 
  and p_container = 'SM CAN' 
  and l_quantity < 0.2 * avg_quantity;