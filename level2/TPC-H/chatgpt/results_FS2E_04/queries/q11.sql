select
ps_partkey,
sum(ps_supplycost * ps_availqty) as part_value
from
partsupp ps
join supplier s on ps.ps_suppkey = s.s_suppkey
join nation n on s.s_nationkey = n.n_nationkey
where
n.n_name = 'UNITED STATES'
group by
ps_partkey
having
sum(ps_supplycost * ps_availqty) >
(
select
0.0001000000 * sum(ps2.ps_supplycost * ps2.ps_availqty)
from
partsupp ps2
join supplier s2 on ps2.ps_suppkey = s2.s_suppkey
join nation n2 on s2.s_nationkey = n2.n_nationkey
where
n2.n_name = 'UNITED STATES'
)
order by
part_value desc;
