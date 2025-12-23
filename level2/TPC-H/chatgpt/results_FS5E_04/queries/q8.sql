select
extract(year from l.l_shipdate) as o_year,
sum(case when n.n_name = 'KENYA' then l.l_extendedprice * (1 - l.l_discount) else 0 end)
/ sum(l.l_extendedprice * (1 - l.l_discount)) as market_share
from
lineitem l
join part p on p.p_partkey = l.l_partkey
join supplier s on s.s_suppkey = l.l_suppkey
join nation n on s.s_nationkey = n.n_nationkey
join region r on n.n_regionkey = r.r_regionkey
where
r.r_name = 'AFRICA'
and p.p_type = 'ECONOMY PLATED BRASS'
and l.l_shipdate >= date '1995-01-01'
and l.l_shipdate < date '1995-01-01' + interval '2' year
group by
extract(year from l.l_shipdate)
order by
o_year;
