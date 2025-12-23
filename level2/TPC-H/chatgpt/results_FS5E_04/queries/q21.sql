select
s.s_suppkey,
s.s_name,
s.s_address,
s.s_phone,
s.s_acctbal,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue_lost
from
supplier s
join lineitem l on s.s_suppkey = l.l_suppkey
join orders o on l.l_orderkey = o.o_orderkey
join nation n on s.s_nationkey = n.n_nationkey
where
n.n_name = 'ETHIOPIA'
and o.o_orderstatus = 'F'
and l.l_receiptdate > l.l_commitdate
-- ensure order involves more than one supplier
and exists (
select 1
from lineitem l2
where l2.l_orderkey = l.l_orderkey
and l2.l_suppkey <> l.l_suppkey
)
-- ensure no other supplier for the same order was late
and not exists (
select 1
from lineitem l3
where l3.l_orderkey = l.l_orderkey
and l3.l_suppkey <> l.l_suppkey
and l3.l_receiptdate > l3.l_commitdate
)
group by
s.s_suppkey,
s.s_name,
s.s_address,
s.s_phone,
s.s_acctbal
order by
revenue_lost desc
limit 100;
