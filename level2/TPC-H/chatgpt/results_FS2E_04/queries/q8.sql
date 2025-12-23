with revenue as (
select
extract(year from o_orderdate) as yr,
n_name as nation,
sum(l_extendedprice * (1 - l_discount)) as rev
from
lineitem l
join orders o on o.o_orderkey = l.l_orderkey
join part p on p.p_partkey = l.l_partkey
join supplier s on s.s_suppkey = l.l_suppkey
join nation n on n.n_nationkey = s.s_nationkey
join region r on r.r_regionkey = n.n_regionkey
where
r.r_name = 'AFRICA'
and p.p_type = 'ECONOMY PLATED BRASS'
and extract(year from o.o_orderdate) in (1995, 1996)
group by
yr, nation
),
tot as (
select yr, sum(rev) as total_rev
from revenue
group by yr
),
ken as (
select yr, rev as kenya_rev
from revenue
where nation = 'KENYA'
)
select
t.yr,
ken.kenya_rev / t.total_rev as market_share
from
tot t
join ken on ken.yr = t.yr
order by
t.yr;
