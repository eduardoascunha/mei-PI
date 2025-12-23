select
n1.n_name as supp_nation,
n2.n_name as cust_nation,
extract(year from l_shipdate) as l_year,
sum(l_extendedprice * (1 - l_discount)) as revenue
from
supplier,
lineitem,
orders,
customer,
nation n1,
nation n2
where
s_suppkey = l_suppkey
and l_orderkey = o_orderkey
and o_custkey = c_custkey
and s_nationkey = n1.n_nationkey
and c_nationkey = n2.n_nationkey
and (
(n1.n_name = 'ARGENTINA' and n2.n_name = 'KENYA')
or (n1.n_name = 'KENYA' and n2.n_name = 'ARGENTINA')
)
and l_shipdate >= date '1995-01-01'
and l_shipdate < date '1995-01-01' + interval '2' year
group by
n1.n_name,
n2.n_name,
extract(year from l_shipdate)
order by
n1.n_name,
n2.n_name,
l_year;
