select
o_year,
sum(l_extendedprice * (1 - l_discount)) / total_revenue as market_share
from
(
select
extract(year from o_orderdate) as o_year,
l_extendedprice * (1 - l_discount) as revenue,
s_nationkey,
p_type
from
lineitem,
orders,
supplier,
partsupp,
part,
nation,
region
where
o_orderkey = l_orderkey
and l_suppkey = s_suppkey
and ps_suppkey = s_suppkey
and ps_partkey = l_partkey
and p_partkey = ps_partkey
and s_nationkey = n_nationkey
and n_regionkey = r_regionkey
and r_name = 'AFRICA'
and p_type = 'ECONOMY PLATED BRASS'
and n_name = 'KENYA'
and extract(year from o_orderdate) in (1995, 1996)
) as market_data
join
(
select
extract(year from o_orderdate) as o_year,
sum(l_extendedprice * (1 - l_discount)) as total_revenue
from
lineitem,
orders,
part,
supplier,
partsupp,
nation,
region
where
o_orderkey = l_orderkey
and l_suppkey = s_suppkey
and ps_suppkey = s_suppkey
and ps_partkey = l_partkey
and p_partkey = ps_partkey
and s_nationkey = n_nationkey
and n_regionkey = r_regionkey
and r_name = 'AFRICA'
and p_type = 'ECONOMY PLATED BRASS'
and extract(year from o_orderdate) in (1995, 1996)
group by
o_year
) as total_data
on
market_data.o_year = total_data.o_year
group by
o_year
order by
o_year;
