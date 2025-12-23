select
s.s_acctbal,
s.s_name,
n.n_name,
s.s_address,
s.s_phone,
count(*) as numwait
from
supplier s
join nation n on s.s_nationkey = n.n_nationkey
join lineitem l on s.s_suppkey = l.l_suppkey
join orders o on o.o_orderkey = l.l_orderkey
where
n.n_name = 'ETHIOPIA'
and o.o_orderstatus = 'F'
and l.l_receiptdate > l.l_commitdate
and exists (
select 1
from lineitem l2
where l2.l_orderkey = l.l_orderkey
and l2.l_suppkey <> l.l_suppkey
)
and not exists (
select 1
from lineitem l3
where l3.l_orderkey = l.l_orderkey
and l3.l_suppkey <> l.l_suppkey
and l3.l_receiptdate > l3.l_commitdate
)
group by
s.s_acctbal,
s.s_name,
n.n_name,
s.s_address,
s.s_phone
order by
numwait desc,
s.s_name
limit 100;
