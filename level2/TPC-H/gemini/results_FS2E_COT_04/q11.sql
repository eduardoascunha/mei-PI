select
	ps_partkey,
	sum(ps_availqty * ps_supplycost) as value
from
	partsupp,
	supplier,
	nation
where
	ps_suppkey = s_suppkey
	and s_nationkey = n_nationkey
	and n_name = 'UNITED STATES'
group by
	ps_partkey
having
	sum(ps_availqty * ps_supplycost) > (
		select
			sum(ps_availqty * ps_supplycost) * 0.0001000000
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