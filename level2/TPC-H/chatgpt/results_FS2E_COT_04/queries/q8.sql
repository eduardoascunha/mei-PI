select
extract(year from o.o_orderdate) as o_year,
sum(case when n.n_name = 'KENYA' then l.l_extendedprice * (1 - l.l_discount) else 0 end)
/ sum(l.l_extendedprice * (1 - l.l_discount)) as market_share
from
part p
join lineitem l on p.p_partkey = l.l_partkey
join supplier s on s.s_suppkey = l.l_suppkey
join nation n on s.s_nationkey = n.n_nationkey
join region r on n.n_regionkey = r.r_regionkey
join orders o on o.o_orderkey = l.l_orderkey
where
r.r_name = 'AFRICA'
and p.p_type like 'ECONOMY PLATED BRASS'
and extract(year from o.o_orderdate) in (1995, 1996)
group by
extract(year from o.o_orderdate)
order by
o_year;
