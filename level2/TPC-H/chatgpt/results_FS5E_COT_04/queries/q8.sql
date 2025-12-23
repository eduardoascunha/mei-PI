select
extract(year from o_orderdate) as o_year,
sum(case
when s_nationkey = n_nationkey
then l_extendedprice * (1 - l_discount)
else 0
end) / sum(l_extendedprice * (1 - l_discount)) as market_share
from
part,
supplier,
lineitem,
partsupp,
orders,
nation,
region
where
p_partkey = l_partkey
and ps_partkey = l_partkey
and ps_suppkey = l_suppkey
and o_orderkey = l_orderkey
and s_suppkey = l_suppkey
and s_nationkey = n_nationkey
and n_regionkey = r_regionkey
and p_type = 'ECONOMY PLATED BRASS'
and r_name = 'AFRICA'
and n_name = 'KENYA'
and o_orderdate >= date '1995-01-01' and o_orderdate < date '1995-01-01' + interval '1' year
group by
o_year
union all
select
extract(year from o_orderdate) as o_year,
sum(case
when s_nationkey = n_nationkey
then l_extendedprice * (1 - l_discount)
else 0
end) / sum(l_extendedprice * (1 - l_discount)) as market_share
from
part,
supplier,
lineitem,
partsupp,
orders,
nation,
region
where
p_partkey = l_partkey
and ps_partkey = l_partkey
and ps_suppkey = l_suppkey
and o_orderkey = l_orderkey
and s_suppkey = l_suppkey
and s_nationkey = n_nationkey
and n_regionkey = r_regionkey
and p_type = 'ECONOMY PLATED BRASS'
and r_name = 'AFRICA'
and n_name = 'KENYA'
and o_orderdate >= date '1996-01-01' and o_orderdate < date '1996-01-01' + interval '1' year
group by
o_year
order by
o_year;
