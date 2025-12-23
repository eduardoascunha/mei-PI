select
s.s_acctbal,
s.s_name,
n.n_name,
p.p_partkey,
p.p_mfgr,
s.s_address,
s.s_phone,
s.s_comment
from
part p,
supplier s,
partsupp ps,
nation n,
region r
where
p.p_partkey = ps.ps_partkey
and ps.ps_suppkey = s.s_suppkey
and s.s_nationkey = n.n_nationkey
and n.n_regionkey = r.r_regionkey
and r.r_name = 'ASIA'
and p.p_size = 2
and p.p_type like '%TIN'
and ps.ps_supplycost = (
select
min(ps2.ps_supplycost)
from
partsupp ps2,
supplier s2,
nation n2,
region r2
where
ps2.ps_partkey = p.p_partkey
and ps2.ps_suppkey = s2.s_suppkey
and s2.s_nationkey = n2.n_nationkey
and n2.n_regionkey = r2.r_regionkey
and r2.r_name = 'ASIA'
)
order by
s.s_acctbal desc,
n.n_name,
s.s_name,
p.p_partkey
limit 100;
