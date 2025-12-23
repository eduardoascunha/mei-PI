select
	count(distinct s_name) as supplier_cnt,
	p_brand,
	p_type,
	p_size
from
	supplier,
	partsupp,
	part
where
	p_partkey = ps_partkey
	and s_suppkey = ps_suppkey
	and s_comment not like '%Customer%Complaints%'
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