select 
	s_name, 
	s_suppkey, 
	sum(l_extendedprice * (1 - l_discount)) as total_revenue
from 
	supplier, 
	lineitem, 
	orders, 
	nation
where 
	s_suppkey = l_suppkey 
	and o_orderkey = l_orderkey 
	and s_nationkey = n_nationkey 
	and o_orderdate >= date '1997-01-01' 
	and o_orderdate < date '1997-01-01' + interval '3' month
group by 
	s_name, 
	s_suppkey
order by 
	total_revenue desc, 
	s_suppkey
limit 1;