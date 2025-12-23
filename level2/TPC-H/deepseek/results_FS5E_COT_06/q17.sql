select
	(sum(l_extendedprice) / 7) * (avg(case when l_quantity < 0.2 * avg_quantity then 1 else 0 end)) as avg_yearly_loss
from
	lineitem,
	part,
	(
		select
			avg(l_quantity) as avg_quantity
		from
			lineitem,
			part
		where
			l_partkey = p_partkey
			and p_brand = 'Brand#23'
			and p_container = 'SM CAN'
	) as avg_query
where
	l_partkey = p_partkey
	and p_brand = 'Brand#23'
	and p_container = 'SM CAN';