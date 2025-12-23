select
s.s_acctbal,
s.s_name,
n.n_name as nation,
p.p_partkey,
p.p_mfgr,
s.s_address,
s.s_phone,
s.s_comment
from
part p
join partsupp ps on p.p_partkey = ps.ps_partkey
join supplier s on ps.ps_suppkey = s.s_suppkey
join nation n on s.s_nationkey = n.n_nationkey
join region r on n.n_regionkey = r.r_regionkey
where
p.p_type like '%TIN'
and p.p_size = 2
and r.r_name = 'ASIA'
and ps.ps_supplycost =
(
select min(ps2.ps_supplycost)
from partsupp ps2
join supplier s2 on ps2.ps_suppkey = s2.s_suppkey
join nation n2 on s2.s_nationkey = n2.n_nationkey
join region r2 on n2.n_regionkey = r2.r_regionkey
where
ps2.ps_partkey = p.p_partkey
and r2.r_name = 'ASIA'
)
order by
s.s_acctbal desc
limit 100;
