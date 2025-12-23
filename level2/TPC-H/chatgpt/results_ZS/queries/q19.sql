select
sum(l_extendedprice * (1 - l_discount)) as revenue
from
lineitem l
join part p on p.p_partkey = l.l_partkey
where
(
p.p_brand = 'Brand#11'
and p.p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
and l.l_quantity between 4 and 14
and p.p_size between 1 and 5
and l.l_shipmode in ('AIR', 'AIR REG')
and l.l_shipinstruct = 'DELIVER IN PERSON'
)
or
(
p.p_brand = 'Brand#25'
and p.p_container in ('MED BAG', 'MED BOX', 'MED PACK', 'MED PKG')
and l.l_quantity between 16 and 26
and p.p_size between 1 and 10
and l.l_shipmode in ('AIR', 'AIR REG')
and l.l_shipinstruct = 'DELIVER IN PERSON'
)
or
(
p.p_brand = 'Brand#54'
and p.p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
and l.l_quantity between 29 and 39
and p.p_size between 1 and 15
and l.l_shipmode in ('AIR', 'AIR REG')
and l.l_shipinstruct = 'DELIVER IN PERSON'
);
