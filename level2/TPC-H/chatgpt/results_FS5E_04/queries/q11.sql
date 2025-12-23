select
ps_partkey as partkey,
sum(ps_supplycost * ps_availqty) as value
from
partsupp
join supplier on ps_suppkey = s_suppkey
join nation on s_nationkey = n_nationkey
where
n_name = 'UNITED STATES'
group by
ps_partkey
having
sum(ps_supplycost * ps_availqty) > 0.0001000000 * (
select
sum(pp.ps_supplycost * pp.ps_availqty)
from
partsupp pp
join supplier sp on pp.ps_suppkey = sp.s_suppkey
join nation na on sp.s_nationkey = na.n_nationkey
where
na.n_name = 'UNITED STATES'
)
order by
value desc;
