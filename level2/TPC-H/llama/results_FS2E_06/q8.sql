select 
	extract(year from o_orderdate) as o_year,
	sum(case when nation = 'KENYA' then volume else 0 end) / sum(volume) as mkt_share
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
			nation,
			region
		where 
			p_partkey = l_partkey
			and s_suppkey = l_suppkey
			and l_orderkey = o_orderkey
			and o_custkey = c_custkey
			and s_nationkey = n_nationkey
			and n_regionkey = r_regionkey
			and r_name = 'AFRICA'
			and p_type = 'ECONOMY PLATED BRASS'
	) as all_nations
group by 
	extract(year from o_orderdate)
order by 
	o_year;