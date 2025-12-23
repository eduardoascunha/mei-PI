select
sum(l_extendedprice * (1 - l_discount)) as revenue
from
lineitem,
part
where
l_partkey = p_partkey
and l_shipinstruct = 'DELIVER IN PERSON'
and l_shipmode like 'AIR%'
and (
(
p_brand = 'Brand#11'
and p_container in ('SM CASE','SM BOX','SM PACK')
and p_size between 1 and 4
)
or (
p_brand = 'Brand#25'
and p_container in ('SM CASE','SM BOX','SM PACK')
and p_size between 5 and 16
)
or (
p_brand = 'Brand#54'
and p_container in ('SM CASE','SM BOX','SM PACK')
and p_size between 17 and 29
)
);
