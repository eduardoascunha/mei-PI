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
		(p_brand = 'Brand#11' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')) 
		or (p_brand = 'Brand#25' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')) 
		or (p_brand = 'Brand#54' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG'))
	)
	and l_quantity between 4 and 16 
	and p_size between 1 and 29;