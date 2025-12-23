select
ns.n_name as supp_nation,
nc.n_name as cust_nation,
extract(year from l.l_shipdate) as l_year,
sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from
supplier s
join lineitem l on s.s_suppkey = l.l_suppkey
join orders o on l.l_orderkey = o.o_orderkey
join customer c on o.o_custkey = c.c_custkey
join nation ns on s.s_nationkey = ns.n_nationkey
join nation nc on c.c_nationkey = nc.n_nationkey
where
ns.n_name in ('ARGENTINA','KENYA')
and nc.n_name in ('ARGENTINA','KENYA')
and ns.n_name <> nc.n_name
and l.l_shipdate between date '1995-01-01' and date '1996-12-31'
group by
ns.n_name,
nc.n_name,
extract(year from l.l_shipdate)
order by
ns.n_name,
nc.n_name,
l_year;
