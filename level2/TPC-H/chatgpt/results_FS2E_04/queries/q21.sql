select distinct
s.s_suppkey,
s.s_name,
n.n_name,
l.l_orderkey
from supplier s
join nation n on s.s_nationkey = n.n_nationkey
join lineitem l on l.l_suppkey = s.s_suppkey
join orders o on o.o_orderkey = l.l_orderkey
where n.n_name = 'ETHIOPIA'
and o.o_orderstatus = 'F'
and l.l_receiptdate > l.l_commitdate
and exists (
select 1
from lineitem lx
where lx.l_orderkey = l.l_orderkey
and lx.l_suppkey <> l.l_suppkey
)
and not exists (
select 1
from lineitem ly
where ly.l_orderkey = l.l_orderkey
and ly.l_suppkey <> l.l_suppkey
and ly.l_receiptdate > ly.l_commitdate
)
limit 100;
