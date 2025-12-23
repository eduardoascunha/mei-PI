select
    c.c_name,
    c.c_address,
    n.n_name,
    c.c_phone,
    c.c_acctbal,
    c.c_comment,
    sum(l.l_extendedprice * (1 - l.l_discount)) as lost_revenue
from
    customer c
    join nation n on c.c_nationkey = n.n_nationkey
    join orders o on c.c_custkey = o.o_custkey
    join lineitem l on o.o_orderkey = l.l_orderkey
where
    l.l_returnflag = 'R'
    and o.o_orderdate >= date '1993-08-01'
    and o.o_orderdate < date '1993-08-01' + interval '3' month
group by
    c.c_custkey,
    c.c_name,
    c.c_address,
    n.n_name,
    c.c_phone,
    c.c_acctbal,
    c.c_comment
order by
    lost_revenue desc
limit 20;