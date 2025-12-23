select
s_acctbal,
s_name,
n_name,
p_partkey,
p_mfgr,
s_address,
s_phone,
s_comment
from
supplier,
nation,
partsupp,
part,
region
where
s_suppkey = ps_suppkey
and p_partkey = ps_partkey
and s_nationkey = n_nationkey
and n_regionkey = r_regionkey
and r_name = 'ASIA'
and p_size = 2
and p_type like '%TIN'
and ps_supplycost = (
select
min(ps2.ps_supplycost)
from
partsupp ps2,
supplier s2,
nation n2,
region r2
where
ps2.ps_partkey = p_partkey
and ps2.ps_suppkey = s2.s_suppkey
and s2.s_nationkey = n2.n_nationkey
and n2.n_regionkey = r2.r_regionkey
and r2.r_name = 'ASIA'
)
order by
s_acctbal desc,
n_name,
s_name,
p_partkey
fetch first 100 rows only;
