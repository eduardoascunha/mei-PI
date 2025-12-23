select
    substr(c_phone, 1, 2) as country_code,
    count(*) as num_customers,
    sum(c_acctbal) as total_balance
from
    customer
where
    substr(c_phone, 1, 2) in ('30', '31', '28', '21', '26', '33', '10')
    and c_acctbal > (select avg(c_acctbal) from customer where c_acctbal > 0)
    and not exists (
        select 1
        from orders
        where o_custkey = c_custkey
        and o_orderdate >= current_date - interval '7 years'
    )
group by
    substr(c_phone, 1, 2)
order by
    num_customers desc, total_balance desc;