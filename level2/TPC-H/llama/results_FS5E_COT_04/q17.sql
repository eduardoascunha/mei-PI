select
	avg(l_quantity) as avg_yearly_rev_loss
from
	(
		select
			l_quantity
		from
			lineitem,
			part
		where
			l_partkey = p_partkey
			and p_brand = 'Brand#23'
			and p_container = 'SM CAN'
	) as part_lineitem
where
	l_quantity < (
		select
			0.2 * avg(l_quantity)
		from
			lineitem,
			part
		where
			l_partkey = p_partkey
			and p_brand = 'Brand#23'
			and p_container = 'SM CAN'
	);