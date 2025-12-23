select
c.c_name,
c.c_custkey,
o.o_orderkey,
o.o_orderdate,
o.o_totalprice,
q.total_qty
from
orders o
join customer c on c.c_custkey = o.o_custkey
join (
select
l_orderkey,
sum(l_quantity) as total_qty
from
lineitem
group by
l_orderkey
) q on q.l_orderkey = o.o_orderkey
where
q.total_qty > 314
order by
q.total_qty desc
limit 100;
