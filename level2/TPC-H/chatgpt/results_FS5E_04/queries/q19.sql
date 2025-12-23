select
sum(l_extendedprice * (1 - l_discount)) as discounted_revenue
from
lineitem
join part on l_partkey = p_partkey
where
l_shipmode = 'AIR'
and l_shipinstruct = 'DELIVER IN PERSON'
and (
(p_brand = 'Brand#11'
and p_container in ('SM CASE','SM BOX','SM PACK')
and p_size between 4 and 14)
or (p_brand = 'Brand#25'
and p_container in ('MED PACK','MED BOX')
and p_size between 16 and 26)
or (p_brand = 'Brand#54'
and p_container in ('LG PACK','LG BOX')
and p_size between 29 and 39)
);
