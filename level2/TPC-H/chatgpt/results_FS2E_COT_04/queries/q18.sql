select
c_name,
c_custkey,
o_orderkey,
o_orderdate,
o_totalprice,
sum_qty
from
customer,
orders,
(
select
l_orderkey,
sum(l_quantity) as sum_qty
from
lineitem
group by
l_orderkey
having
sum(l_quantity) > 314
) as ordqty (l_orderkey, sum_qty)
where
c_custkey = o_custkey
and o_orderkey = ordqty.l_orderkey
order by
sum_qty desc,
o_totalprice desc
limit 100;
