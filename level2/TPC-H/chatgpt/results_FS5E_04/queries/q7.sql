select
sn.n_name as supplier_nation,
cn.n_name as customer_nation,
extract(year from l_shipdate) as ship_year,
sum(l_extendedprice * (1 - l_discount)) as revenue
from
lineitem,
orders,
supplier,
customer,
nation sn,
nation cn
where
l_orderkey = o_orderkey
and l_suppkey = s_suppkey
and o_custkey = c_custkey
and s_nationkey = sn.n_nationkey
and c_nationkey = cn.n_nationkey
and extract(year from l_shipdate) in (1995, 1996)
and (
(sn.n_name = 'ARGENTINA' and cn.n_name = 'KENYA')
or
(sn.n_name = 'KENYA' and cn.n_name = 'ARGENTINA')
)
group by
sn.n_name,
cn.n_name,
extract(year from l_shipdate)
order by
sn.n_name,
cn.n_name,
ship_year;
