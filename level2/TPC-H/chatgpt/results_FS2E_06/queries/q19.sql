select
sum(l_extendedprice * (1 - l_discount)) as discounted_revenue
from
lineitem
join part on p_partkey = l_partkey
where
l_shipmode in ('AIR', 'AIR REG')
and l_shipinstruct = 'DELIVER IN PERSON'
and (
(p_brand = 'Brand#11'
and p_container in ('SM CASE','SM BOX')
and p_size between 1 and 4)
or (p_brand = 'Brand#25'
and p_container in ('SM CASE','SM BOX')
and p_size between 1 and 16)
or (p_brand = 'Brand#54'
and p_container in ('SM CASE','SM BOX')
and p_size between 1 and 29)
);
