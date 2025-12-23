select
	count(distinct s_name) as supplier_cnt,
	p_brand,
	p_type,
	p_size
from
	supplier,
	partsupp,
	part,
	nation
where
	s_suppkey = ps_suppkey
	and ps_partkey = p_partkey
	and s_nationkey = n_nationkey
	and s_comment not like '%Better Business Bureau%'
	and p_brand <> 'Brand#42'
	and p_type not like 'LARGE PLATED%'
	and p_size in (9, 7, 14, 41, 43, 38, 23, 34)
group by
	p_brand,
	p_type,
	p_size
order by
	supplier_cnt desc,
	p_brand,
	p_type,
	p_size;