select
sum(l_extendedprice * (1 - l_discount)) as discounted_revenue
from
lineitem,
part
where
l_partkey = p_partkey
and l_shipmode = 'AIR'
and l_shipinstruct = 'DELIVER IN PERSON'
and (
(p_brand = 'Brand#11' and p_size >= 4 and p_size < 16)
or (p_brand = 'Brand#25' and p_size >= 16 and p_size < 29)
or (p_brand = 'Brand#54' and p_size >= 29)
);
