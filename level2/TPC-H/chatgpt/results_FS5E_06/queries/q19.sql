select
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from
lineitem l
join part p on p.p_partkey = l.l_partkey
where
l.l_shipmode = 'AIR'
and l.l_shipinstruct = 'DELIVER IN PERSON'
and (
(p.p_brand = 'Brand#11'
and p.p_container in ('SM CASE','SM BOX','SM PACK','SM PKG')
and p.p_size between 1 and 4)
or (p.p_brand = 'Brand#25'
and p.p_container in ('MED BAG','MED BOX','MED PKG','MED PACK')
and p.p_size between 1 and 16)
or (p.p_brand = 'Brand#54'
and p.p_container in ('LG CASE','LG BOX','LG PACK','LG PKG')
and p.p_size between 1 and 29)
);
