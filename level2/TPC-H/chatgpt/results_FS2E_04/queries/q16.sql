select
p_brand,
p_type,
p_size,
count(distinct s_suppkey) as supplier_count
from
part
join partsupp on p_partkey = ps_partkey
join supplier on s_suppkey = ps_suppkey
where
p_size in (9, 7, 14, 41, 43, 38, 23, 34)
and p_brand <> 'Brand#42'
and p_type not like 'LARGE PLATED%'
and s_comment not like '%Complaint%'
group by
p_brand,
p_type,
p_size
order by
supplier_count desc,
p_brand,
p_type,
p_size;
