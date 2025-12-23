select distinct
s_acctbal,
s_name,
n_name,
s_address,
s_phone,
s_comment
from
supplier,
nation,
lineitem l1,
orders
where
s_suppkey = l1.l_suppkey
and s_nationkey = n_nationkey
and n_name = 'ETHIOPIA'
and l1.l_orderkey = o_orderkey
and o_orderstatus = 'F'
and l1.l_receiptdate > l1.l_commitdate
and exists (
select
1
from
lineitem l2
where
l2.l_orderkey = l1.l_orderkey
and l2.l_suppkey <> l1.l_suppkey
)
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
order by
s_acctbal desc,
n_name,
s_name
limit 100;
