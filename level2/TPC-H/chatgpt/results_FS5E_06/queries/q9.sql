select
n.n_name as nation,
extract(year from o.o_orderdate) as o_year,
sum((l.l_extendedprice * (1 - l.l_discount)) - (ps.ps_supplycost * l.l_quantity)) as profit
from
part p,
lineitem l,
partsupp ps,
supplier s,
nation n,
orders o
where
p.p_partkey = l.l_partkey
and ps.ps_partkey = l.l_partkey
and ps.ps_suppkey = l.l_suppkey
and s.s_suppkey = l.l_suppkey
and s.s_nationkey = n.n_nationkey
and l.l_orderkey = o.o_orderkey
and p.p_name like '%red%'
and l.l_linestatus = 'F'
group by
n.n_name,
extract(year from o.o_orderdate)
order by
n.n_name asc,
o_year desc;
