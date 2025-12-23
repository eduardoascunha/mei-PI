select
sum(l_extendedprice * l_discount) as potential_increase
from
lineitem
where
l_shipdate >= date '1994-01-01'
and l_shipdate < date '1995-01-01'
and l_discount >= 0.02 - 0.01
and l_discount <= 0.02 + 0.01
and l_quantity < 25;
