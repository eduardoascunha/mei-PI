select
ps_partkey,
sum(ps_availqty * ps_supplycost) as part_value
from
partsupp
join supplier on ps_suppkey = s_suppkey
join nation on s_nationkey = n_nationkey
where
n_name = 'UNITED STATES'
group by
ps_partkey
having
sum(ps_availqty * ps_supplycost) >
(
select
sum(ps_availqty * ps_supplycost) * 0.0001000000
from
partsupp
join supplier on ps_suppkey = s_suppkey
join nation on s_nationkey = n_nationkey
where
n_name = 'UNITED STATES'
)
order by
part_value desc;
