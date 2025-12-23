select
n.n_name as nation,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from
lineitem l
join orders o on l.l_orderkey = o.o_orderkey
join customer c on o.o_custkey = c.c_custkey
join supplier s on l.l_suppkey = s.s_suppkey
join nation n on c.c_nationkey = n.n_nationkey and s.s_nationkey = n.n_nationkey
join region r on n.n_regionkey = r.r_regionkey
where
r.r_name = 'EUROPE'
and o.o_orderdate >= date '1994-01-01'
and o.o_orderdate < date '1994-01-01' + interval '1' year
group by
n.n_name
order by
revenue desc;
