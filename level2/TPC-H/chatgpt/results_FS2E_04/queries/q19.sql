select
sum(l_extendedprice * (1 - l_discount)) as revenue
from
lineitem
join part on p_partkey = l_partkey
where
l_shipmode in ('AIR', 'AIR REG')
and l_shipinstruct = 'DELIVER IN PERSON'
and (
(p_brand = 'Brand#11'
and p_container in ('SM CASE','SM BOX','SM PACK','SM PKG')
and p_size between 4 and 16)
or
(p_brand = 'Brand#25'
and p_container in ('MED BAG','MED BOX','MED PACK','MED PKG')
and p_size between 16 and 29)
or
(p_brand = 'Brand#54'
and p_container in ('LG CASE','LG BOX','LG PACK','LG PKG')
and p_size >= 29)
)
