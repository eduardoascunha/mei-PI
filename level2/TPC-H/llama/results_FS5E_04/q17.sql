select
	avg(l_quantity) as avg_yearly_revenue_loss
from
	lineitem,
	part
where
	p_partkey = l_partkey
	and p_brand = 'Brand#23'
	and p_container = 'SM CAN'
	and l_quantity < (
		select
			0.2 * avg(l_quantity)
		from
			lineitem,
			part
		where
			p_partkey = l_partkey
			and p_brand = 'Brand#23'
			and p_container = 'SM CAN'
	);