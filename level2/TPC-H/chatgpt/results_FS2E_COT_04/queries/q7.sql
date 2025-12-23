select
sn.n_name as supplier_nation,
cn.n_name as customer_nation,
extract(year from l.l_shipdate) as l_year,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from
supplier s,
lineitem l,
orders o,
customer c,
nation sn,
nation cn
where
s.s_suppkey = l.l_suppkey
and l.l_orderkey = o.o_orderkey
and o.o_custkey = c.c_custkey
and s.s_nationkey = sn.n_nationkey
and c.c_nationkey = cn.n_nationkey
and (
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
l_year;
