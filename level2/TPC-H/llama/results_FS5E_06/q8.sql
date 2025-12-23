select
	nation,
	o_year,
	sum(amount) / sum(total_revenue) as mkt_share
from
	(
		select
			n_name as nation,
			extract(year from o_orderdate) as o_year,
			l_extendedprice * (1 - l_discount) as amount,
			sum(l_extendedprice * (1 - l_discount)) over (partition by n_name, extract(year from o_orderdate)) as total_revenue
		from
			part,
			supplier,
			lineitem,
			orders,
			customer,
			nation,
			region
		where
			c_custkey = o_custkey
			and o_orderkey = l_orderkey
			and l_partkey = p_partkey
			and l_suppkey = s_suppkey
			and c_nationkey = n_nationkey
			and s_nationkey = n_nationkey
			and n_regionkey = r_regionkey
			and r_name = 'AFRICA'
			and p_type = 'ECONOMY PLATED BRASS'
			and n_name = 'KENYA'
	) as all_nations_revenue
group by
	nation,
	o_year
order by
	o_year;