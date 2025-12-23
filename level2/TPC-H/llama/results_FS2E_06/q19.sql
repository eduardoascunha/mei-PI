select
	sum(l_extendedprice * (1 - l_discount)) as revenue
from
	lineitem,
	part
where
	l_partkey = p_partkey
	and l_shipmode = 'AIR'
	and l_shipinstruct = 'DELIVER IN PERSON'
	and (
		(p_brand = 'Brand#11' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and p_size between 1 and 4)
		or (p_brand = 'Brand#25' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') and p_size between 10 and 16)
		or (p_brand = 'Brand#54' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and p_size between 20 and 29)
	);