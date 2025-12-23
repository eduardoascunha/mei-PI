select
c_name,
c_address,
n_name as nation,
c_phone,
c_acctbal,
c_comment,
sum(l_extendedprice * (1 - l_discount)) as revenue_lost
from
customer
join orders on c_custkey = o_custkey
join lineitem on o_orderkey = l_orderkey
join nation on c_nationkey = n_nationkey
where
o_orderdate >= date '1993-08-01'
and o_orderdate < date '1993-08-01' + interval '3 month'
and l_returnflag = 'R'
group by
c_name,
c_address,
n_name,
c_phone,
c_acctbal,
c_comment
order by
revenue_lost desc
limit 20;
