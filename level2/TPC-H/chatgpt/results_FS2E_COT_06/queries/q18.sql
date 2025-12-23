select
c_name,
c_custkey,
o_orderkey,
o_orderdate,
o_totalprice,
lt.total_quantity
from
customer,
orders,
(
select
l_orderkey,
sum(l_quantity) as total_quantity
from
lineitem
group by
l_orderkey
having
sum(l_quantity) > 314
) as lt
where
c_custkey = o_custkey
and o_orderkey = lt.l_orderkey
order by
lt.total_quantity desc,
o_totalprice desc
fetch first 100 rows only;
