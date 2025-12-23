SQL QUERY:
select
s.s_suppkey,
s.s_name,
s.s_address,
s.s_phone,
s.s_acctbal,
n.n_name,
o.o_orderkey,
o.o_orderstatus,
l.l_shipdate,
l.l_commitdate,
l.l_receiptdate
from
supplier s,
orders o,
lineitem l,
nation n
where
o.o_orderkey = l.l_orderkey
and l.l_suppkey = s.s_suppkey
and o.o_custkey = l.l_orderkey
and s.s_nationkey = n.n_nationkey
and n.n_name = 'ETHIOPIA'
and o.o_orderstatus = 'F'
and l.l_commitdate < l.l_receiptdate
and not exists (
select 1
from
lineitem l2
where
l2.l_orderkey = l.l_orderkey
and l2.l_suppkey <> l.l_suppkey
and l2.l_commitdate >= l.l_commitdate
)
limit 100;
