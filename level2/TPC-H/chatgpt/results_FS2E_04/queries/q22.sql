select
count(*) as cust_cnt,
sum(c.c_acctbal) as total_acctbal
from
customer c
left join orders o
on c.c_custkey = o.o_custkey
and o.o_orderdate >= current_date - interval '7 years'
where
substring(c.c_phone from 1 for 2) in ('30','31','28','21','26','33','10')
and o.o_orderkey is null
and c.c_acctbal > (
select avg(c_acctbal)
from customer
where c_acctbal > 0
)
