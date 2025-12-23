select
c_name,
c_custkey,
o_orderkey,
o_orderdate,
o_totalprice,
sum(l_quantity) as orderqty
from
customer,
orders,
lineitem
where
c_custkey = o_custkey
and l_orderkey = o_orderkey
group by
c_name,
c_custkey,
o_orderkey,
o_orderdate,
o_totalprice
having
sum(l_quantity) > 314
order by
orderqty desc,
o_totalprice desc
limit 100;
