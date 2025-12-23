select
ns.n_name as supplier_nation,
nc.n_name as customer_nation,
extract(year from l_shipdate) as ship_year,
sum(l_extendedprice * (1 - l_discount)) as revenue
from
supplier s
join nation ns on s.s_nationkey = ns.n_nationkey
join lineitem li on li.l_suppkey = s.s_suppkey
join orders o on o.o_orderkey = li.l_orderkey
join customer c on c.c_custkey = o.o_custkey
join nation nc on c.c_nationkey = nc.n_nationkey
where
(
(ns.n_name = 'ARGENTINA' and nc.n_name = 'KENYA')
or
(ns.n_name = 'KENYA' and nc.n_name = 'ARGENTINA')
)
and li.l_shipdate >= date '1995-01-01'
and li.l_shipdate < date '1997-01-01'
group by
ns.n_name,
nc.n_name,
extract(year from l_shipdate)
order by
supplier_nation,
customer_nation,
ship_year;
