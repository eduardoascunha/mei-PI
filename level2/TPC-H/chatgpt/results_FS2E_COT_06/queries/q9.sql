select
n_name as nation,
extract(year from o_orderdate) as o_year,
sum((l_extendedprice * (1 - l_discount)) - (ps_supplycost * l_quantity)) as profit
from
part,
supplier,
lineitem,
orders,
partsupp,
customer,
nation
where
p_partkey = l_partkey
and s_suppkey = l_suppkey
and l_orderkey = o_orderkey
and o_custkey = c_custkey
and c_nationkey = n_nationkey
and p_partkey = ps_partkey
and p_name like '%red%'
and o_orderdate between date '1995-01-01' and date '1996-12-31'
group by
n_name,
o_year
order by
n_name asc,
o_year desc;
