select
	extract(year from o_orderdate) as o_year,
	sum(case
		when nation = 'KENYA' then volume
		else 0
	end) / sum(volume) as mkt_share
from
	(
		select
			o_orderdate,
			l_extendedprice * (1 - l_discount) as volume,
			n_name as nation
		from
			part,
			supplier,
			lineitem,
			orders,
			customer,
			nation,
			region
		where
			p_partkey = l_partkey
			and s_suppkey = l_suppkey
			and l_orderkey = o_orderkey
			and o_custkey = c_custkey
			and c_nationkey = n_nationkey
			and n_regionkey = r_regionkey
			and r_name = 'AFRICA'
			and o_orderdate between '1995-01-01' and '1996-12-31'
			and p_type = 'ECONOMY PLATED BRASS'
	) as all_nations
group by
	o_year
order by
	o_year;