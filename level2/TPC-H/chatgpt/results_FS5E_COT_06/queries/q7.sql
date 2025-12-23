select
sn.n_name as supp_nation,
cn.n_name as cust_nation,
extract(year from l_shipdate) as l_year,
sum(l_extendedprice * (1 - l_discount)) as revenue
from
lineitem,
supplier,
orders,
customer,
nation sn,
nation cn
where
l_suppkey = s_suppkey
and l_orderkey = o_orderkey
and o_custkey = c_custkey
and s_nationkey = sn.n_nationkey
and c_nationkey = cn.n_nationkey
and l_shipdate between date '1995-01-01' and date '1996-12-31'
and (
(sn.n_name = 'ARGENTINA' and cn.n_name = 'KENYA')
or (sn.n_name = 'KENYA' and cn.n_name = 'ARGENTINA')
)
group by
sn.n_name,
cn.n_name,
l_year
order by
sn.n_name,
cn.n_name,
l_year;
