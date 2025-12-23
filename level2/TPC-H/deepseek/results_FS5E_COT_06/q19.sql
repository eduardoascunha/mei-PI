select
	sum(l_extendedprice * (1 - l_discount)) as revenue
from
	lineitem,
	part
where
	l_partkey = p_partkey
	and p_brand in ('Brand#11', 'Brand#25', 'Brand#54')
	and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG', 'MED CASE', 'MED BOX', 'MED PACK', 'MED PKG', 'LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
	and p_size between 1 and 15
	and l_shipmode = 'AIR'
	and l_shipinstruct = 'DELIVER IN PERSON'
	and (
		(p_brand = 'Brand#11' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and l_quantity >= 4 and l_quantity <= 4 + 10)
		or (p_brand = 'Brand#25' and p_container in ('MED CASE', 'MED BOX', 'MED PACK', 'MED PKG') and l_quantity >= 16 and l_quantity <= 16 + 10)
		or (p_brand = 'Brand#54' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and l_quantity >= 29 and l_quantity <= 29 + 10)
	);