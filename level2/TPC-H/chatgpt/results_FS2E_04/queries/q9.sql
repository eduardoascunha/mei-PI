select
n.n_name,
extract(year from o.o_orderdate) as o_year,
sum((l.l_extendedprice * (1 - l.l_discount)) - (ps.ps_supplycost * l.l_quantity)) as profit
from
supplier s
join nation n on s.s_nationkey = n.n_nationkey
join lineitem l on s.s_suppkey = l.l_suppkey
join orders o on l.l_orderkey = o.o_orderkey
join part p on l.l_partkey = p.p_partkey
join partsupp ps on p.p_partkey = ps.ps_partkey and s.s_suppkey = ps.ps_suppkey
where
p.p_name like '%red%'
group by
n.n_name,
extract(year from o.o_orderdate)
order by
n.n_name asc,
o_year desc;
