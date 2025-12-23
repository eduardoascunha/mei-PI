select
c.c_name,
c.c_custkey,
o.o_orderkey,
o.o_orderdate,
o.o_totalprice,
sum(l.l_quantity) as total_quantity
from
orders o
join customer c on c.c_custkey = o.o_custkey
join lineitem l on l.l_orderkey = o.o_orderkey
group by
c.c_name,
c.c_custkey,
o.o_orderkey,
o.o_orderdate,
o.o_totalprice
having
sum(l.l_quantity) > 314
order by
total_quantity desc
limit 100;
