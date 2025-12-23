select
p_brand,
p_type,
p_size,
count(distinct ps_suppkey) as supplier_cnt
from
part,
partsupp,
supplier
where
p_partkey = ps_partkey
and ps_suppkey = s_suppkey
and p_brand <> 'Brand#42'
and p_type not like 'LARGE PLATED%'
and p_size in (9,7,14,41,43,38,23,34)
and s_comment not like '%Customer%Complaints%'
group by
p_brand,
p_type,
p_size
order by
supplier_cnt desc,
p_brand,
p_type,
p_size;
