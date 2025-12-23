with avg_pos as (
select avg(c_acctbal) as avg_acctbal
from customer
where c_acctbal > 0
)
select
substring(c_phone from 1 for 2) as cntrycode,
count(*) as numcust,
sum(c_acctbal) as totacctbal
from
customer,
avg_pos
where
substring(c_phone from 1 for 2) in ('30','31','28','21','26','33','10')
and c_acctbal > avg_pos.avg_acctbal
and not exists (
select 1
from orders o
where o.o_custkey = customer.c_custkey
and o.o_orderdate >= date '1993-01-01'
and o.o_orderdate < date '2000-01-01'
)
group by
substring(c_phone from 1 for 2)
order by
substring(c_phone from 1 for 2);
