with avg_pos as (
select avg(c_acctbal) as avg_acctbal
from customer
where c_acctbal > 0
)
select
substring(c.c_phone from 1 for 2) as country_code,
count(*) as num_customers,
sum(c.c_acctbal) as total_acctbal,
avg(c.c_acctbal) as avg_acctbal
from
customer c,
avg_pos ap
where
substring(c.c_phone from 1 for 2) in ('30','31','28','21','26','33','10')
and c.c_acctbal > ap.avg_acctbal
and c.c_acctbal > 0
and not exists (
select 1
from orders o
where o.o_custkey = c.c_custkey
and o.o_orderdate >= current_date - interval '7' year
)
group by
substring(c.c_phone from 1 for 2)
order by
country_code;
