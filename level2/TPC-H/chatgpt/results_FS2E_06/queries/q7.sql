select
sn.n_name as supplier_nation,
cn.n_name as customer_nation,
extract(year from l.l_shipdate) as year,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from
lineitem l
join orders o on o.o_orderkey = l.l_orderkey
join customer c on c.c_custkey = o.o_custkey
join supplier s on s.s_suppkey = l.l_suppkey
join nation sn on sn.n_nationkey = s.s_nationkey
join nation cn on cn.n_nationkey = c.c_nationkey
where
l.l_shipdate >= date '1995-01-01'
and l.l_shipdate < date '1997-01-01'
and (
(sn.n_name = 'ARGENTINA' and cn.n_name = 'KENYA')
or
(sn.n_name = 'KENYA' and cn.n_name = 'ARGENTINA')
)
group by
sn.n_name,
cn.n_name,
extract(year from l.l_shipdate)
order by
supplier_nation,
customer_nation,
year;
