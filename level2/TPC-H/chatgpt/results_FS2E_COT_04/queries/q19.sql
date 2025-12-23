select
sum(l_extendedprice * (1 - l_discount)) as revenue
from
part,
lineitem
where
p_partkey = l_partkey
and l_shipmode = 'AIR'
and l_shipinstruct = 'DELIVER IN PERSON'
and (
(p_brand = 'Brand#11'
and p_container in ('SM CASE','SM BOX','SM PACK')
and p_size between 1 and 4)
or (p_brand = 'Brand#25'
and p_container in ('MED BAG','MED BOX','MED PKG')
and p_size between 5 and 16)
or (p_brand = 'Brand#54'
and p_container in ('LG CASE','LG BOX','LG PACK')
and p_size between 17 and 29)
);
