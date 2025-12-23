select
p.p_brand,
p.p_type,
p.p_size,
count(distinct s.s_suppkey) as supplier_count
from
part p
join partsupp ps on p.p_partkey = ps.ps_partkey
join supplier s on ps.ps_suppkey = s.s_suppkey
where
p.p_brand <> 'Brand#42'
and p.p_type not like 'LARGE PLATED%'
and p.p_size in (9, 7, 14, 41, 43, 38, 23, 34)
and s.s_comment not ilike '%bbb%'
and s.s_comment not ilike '%better business bureau%'
and s.s_comment not ilike '%complaint%'
group by
p.p_brand,
p.p_type,
p.p_size
order by
supplier_count desc,
p.p_brand asc,
p.p_type asc,
p.p_size asc;
