select
c.c_name,
c.c_address,
n.n_name,
c.c_phone,
c.c_acctbal,
c.c_comment,
sum(l.l_extendedprice * (1 - l.l_discount)) as lost_revenue
from customer c
join orders o on o.o_custkey = c.c_custkey
join lineitem l on l.l_orderkey = o.o_orderkey
join nation n on n.n_nationkey = c.c_nationkey
where o.o_orderdate >= date '1993-08-01'
and o.o_orderdate <  date '1993-08-01' + interval '3 months'
and l.l_returnflag = 'R'
group by
c.c_name,
c.c_address,
n.n_name,
c.c_phone,
c.c_acctbal,
c.c_comment
order by lost_revenue desc
limit 20;
