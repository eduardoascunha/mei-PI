select
p_brand,
p_type,
p_size,
count(distinct s_suppkey) as supplier_count
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
and s_comment not like '%Complaints%'
group by
p_brand,
p_type,
p_size
order by
supplier_count desc,
p_brand asc,
p_type asc,
p_size asc;
