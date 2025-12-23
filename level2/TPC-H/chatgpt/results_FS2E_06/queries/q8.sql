select
yr,
case
when denom = 0 then null
else num / denom
end as market_share
from (
select
extract(year from o_orderdate) as yr,
sum(case when n_name = 'KENYA' then l_extendedprice * (1 - l_discount) else 0 end) as num,
sum(l_extendedprice * (1 - l_discount)) as denom
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
and extract(year from o_orderdate) in (1995, 1996)
group by
extract(year from o_orderdate)
) t
order by
yr;
