select
c.c_name,
c.c_custkey,
o.o_orderkey,
o.o_orderdate,
o.o_totalprice,
q.total_qty
from
customer c
join orders o on c.c_custkey = o.o_custkey
join (
select
l_orderkey,
sum(l_quantity) as total_qty
from
lineitem
group by
l_orderkey
having
sum(l_quantity) > 314
) q on o.o_orderkey = q.l_orderkey
order by
q.total_qty desc
limit 100;
