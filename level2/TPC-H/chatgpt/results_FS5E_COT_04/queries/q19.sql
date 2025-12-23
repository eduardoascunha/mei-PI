select
sum(l_extendedprice * (1 - l_discount)) as discounted_revenue
from
lineitem,
part
where
p_partkey = l_partkey
and l_shipmode = 'AIR'
and l_shipinstruct = 'DELIVER IN PERSON'
and (
(p_brand = 'Brand#11' and p_size between 1 and 10) or
(p_brand = 'Brand#25' and p_size between 10 and 20) or
(p_brand = 'Brand#54' and p_size between 20 and 30)
)
and l_quantity between 4 and 29;
