select
n.n_name,
extract(year from o.o_orderdate) as order_year,
sum((l.l_extendedprice * (1 - l.l_discount)) - (ps.ps_supplycost * l.l_quantity)) as profit
from
lineitem l
join orders o on l.l_orderkey = o.o_orderkey
join part p on l.l_partkey = p.p_partkey
join partsupp ps on l.l_partkey = ps.ps_partkey and l.l_suppkey = ps.ps_suppkey
join supplier s on l.l_suppkey = s.s_suppkey
join nation n on s.s_nationkey = n.n_nationkey
where
p.p_name like '%red%'
group by
n.n_name,
extract(year from o.o_orderdate)
order by
n.n_name,
order_year desc;
