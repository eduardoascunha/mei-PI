select
c_name,
c_address,
n_name as nation,
c_phone,
c_acctbal,
c_comment,
sum(l_extendedprice * (1 - l_discount)) as lost_revenue
from
customer,
nation,
lineitem,
orders
where
c_custkey = o_custkey
and o_orderkey = l_orderkey
and l_returnflag = 'R'
and l_shipdate >= date '1993-08-01'
and l_shipdate < date '1993-08-01' + interval '3' month
and c_nationkey = n_nationkey
group by
c_name,
c_address,
n_name,
c_phone,
c_acctbal,
c_comment
order by
lost_revenue desc
limit 20;
