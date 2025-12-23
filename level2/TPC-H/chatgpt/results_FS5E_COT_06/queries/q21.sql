select distinct
s.s_name,
s.s_address
from
supplier s,
nation n
where
s.s_nationkey = n.n_nationkey
and n.n_name = 'ETHIOPIA'
and s.s_suppkey in (
select
l1.l_suppkey
from
lineitem l1,
orders o
where
l1.l_orderkey = o.o_orderkey
and o.o_orderstatus = 'F'
-- order must have multiple suppliers
and exists (
select
1
from
lineitem l2
where
l2.l_orderkey = l1.l_orderkey
and l2.l_suppkey <> l1.l_suppkey
)
-- this supplier missed commit (late)
and l1.l_receiptdate > l1.l_commitdate
-- no other supplier on same order missed commit
and not exists (
select
1
from
lineitem l3
where
l3.l_orderkey = l1.l_orderkey
and l3.l_suppkey <> l1.l_suppkey
and l3.l_receiptdate > l3.l_commitdate
)
)
order by
s.s_name
limit 100;
