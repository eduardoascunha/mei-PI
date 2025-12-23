select
sn.n_name as supplier_nation,
cn.n_name as customer_nation,
extract(year from l.l_shipdate) as l_year,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from
supplier s
join nation sn on s.s_nationkey = sn.n_nationkey
join lineitem l on l.l_suppkey = s.s_suppkey
join orders o on o.o_orderkey = l.l_orderkey
join customer c on o.o_custkey = c.c_custkey
join nation cn on c.c_nationkey = cn.n_nationkey
where
(
(sn.n_name = 'ARGENTINA' and cn.n_name = 'KENYA')
or (sn.n_name = 'KENYA' and cn.n_name = 'ARGENTINA')
)
and l.l_shipdate >= date '1995-01-01'
and l.l_shipdate < date '1997-01-01'
group by
sn.n_name,
cn.n_name,
extract(year from l.l_shipdate)
order by
sn.n_name,
cn.n_name,
extract(year from l.l_shipdate);
