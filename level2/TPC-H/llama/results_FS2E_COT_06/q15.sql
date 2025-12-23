select
	s_suppkey,
	sum(l_extendedprice * (1 - l_discount)) as total_revenue
from
	supplier,
	lineitem
where
	l_suppkey = s_suppkey
	and l_shipdate >= date '1997-01-01'
	and l_shipdate < date '1997-01-01' + interval '3' month
group by
	s_suppkey
order by
	total_revenue desc,
	s_suppkey
limit 1;