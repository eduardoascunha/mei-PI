select
s_suppkey,
s_name,
n_name
from
supplier,
nation
where
s_nationkey = n_nationkey
and n_name = 'ETHIOPIA'
and s_suppkey in (
select
l_suppkey
from
lineitem l1,
orders o1
where
l1.l_orderkey = o1.o_orderkey
and o1.o_orderstatus = 'F'
and l1.l_commitdate < l1.l_receiptdate
and not exists (
select
1
from
lineitem l2
where
l2.l_orderkey = l1.l_orderkey
and l2.l_suppkey <> l1.l_suppkey
and l2.l_commitdate < l2.l_receiptdate
)
)
order by
s_suppkey
limit 100;
