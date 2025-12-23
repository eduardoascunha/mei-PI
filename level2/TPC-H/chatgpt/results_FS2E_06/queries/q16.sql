select
p_brand,
p_type,
p_size,
count(distinct ps_suppkey) as supp_cnt
from
part
join partsupp on p_partkey = ps_partkey
join supplier on ps_suppkey = s_suppkey
where
p_size in (9, 7, 14, 41, 43, 38, 23, 34)
and p_type not like 'LARGE PLATED%'
and p_brand <> 'Brand#42'
and s_comment not like '%Complaints%'
group by
p_brand,
p_type,
p_size
order by
supp_cnt desc,
p_brand,
p_type,
p_size;
