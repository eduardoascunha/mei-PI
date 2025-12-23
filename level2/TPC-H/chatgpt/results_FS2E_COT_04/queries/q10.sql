select
c.c_name,
c.c_address,
n.n_name,
c.c_phone,
c.c_acctbal,
c.c_comment,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue_lost
from
customer c,
orders o,
lineitem l,
nation n
where
c.c_custkey = o.o_custkey
and o.o_orderkey = l.l_orderkey
and c.c_nationkey = n.n_nationkey
and l.l_returnflag = 'R'
and o.o_orderdate >= date '1993-08-01'
and o.o_orderdate < date '1993-08-01' + interval '3' month
group by
c.c_name,
c.c_address,
n.n_name,
c.c_phone,
c.c_acctbal,
c.c_comment
order by
revenue_lost desc
limit 20;
