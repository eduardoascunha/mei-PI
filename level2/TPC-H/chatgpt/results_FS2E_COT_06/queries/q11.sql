select
p.p_partkey,
sum(ps.ps_supplycost * ps.ps_availqty) as value
from
partsupp ps,
supplier s,
nation n,
part p
where
ps.ps_suppkey = s.s_suppkey
and s.s_nationkey = n.n_nationkey
and n.n_name = 'UNITED STATES'
and p.p_partkey = ps.ps_partkey
group by
p.p_partkey
having
sum(ps.ps_supplycost * ps.ps_availqty) > (
select
sum(ps2.ps_supplycost * ps2.ps_availqty) * 0.0001000000
from
partsupp ps2,
supplier s2,
nation n2
where
ps2.ps_suppkey = s2.s_suppkey
and s2.s_nationkey = n2.n_nationkey
and n2.n_name = 'UNITED STATES'
)
order by
value desc;
