select
n.n_name as nation,
extract(year from o.o_orderdate) as o_year,
sum((l.l_extendedprice * (1 - l.l_discount)) - (ps.ps_supplycost * l.l_quantity)) as profit
from
part p,
supplier s,
partsupp ps,
lineitem l,
orders o,
nation n
where
p.p_partkey = l.l_partkey
and s.s_suppkey = l.l_suppkey
and ps.ps_partkey = l.l_partkey
and ps.ps_suppkey = l.l_suppkey
and l.l_orderkey = o.o_orderkey
and s.s_nationkey = n.n_nationkey
and p.p_name like '%red%'
group by
n.n_name,
extract(year from o.o_orderdate)
order by
n.n_name asc,
extract(year from o.o_orderdate) desc;
