with avg_acctbal as (
  select avg(c_acctbal) as avg_balance
  from customer
  where c_acctbal > 0
)
select 
  count(c_custkey) as cust_count,
  sum(c_acctbal) as total_acctbal
from 
  customer
where 
  c_phone like any (array['30%', '31%', '28%', '21%', '26%', '33%', '10%'])
  and c_custkey not in (
    select o_custkey
    from orders
    where o_orderdate >= now() - interval '7 year'
  )
  and c_acctbal > (select avg_balance from avg_acctbal);