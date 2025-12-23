select
	p_partkey,
	sum(ps_supplycost * ps_availqty) as value
from
	part,
	partsupp,
	supplier,
	nation
where
	p_partkey = ps_partkey
	and ps_suppkey = s_suppkey
	and s_nationkey = n_nationkey
	and n_name = 'UNITED STATES'
group by
	p_partkey
having
	sum(ps_supplycost * ps_availqty) > (
		select
			0.0001000000 * sum(ps_supplycost * ps_availqty)
		from
			partsupp,
			supplier,
			nation
		where
			ps_suppkey = s_suppkey
			and s_nationkey = n_nationkey
			and n_name = 'UNITED STATES'
	)
order by
	value desc;