create view revenue_loss (c_custkey, lost_revenue) as
	select
		o_custkey,
		sum(l_extendedprice * (1 - l_discount))
	from
		lineitem,
		orders
	where
		l_orderkey = o_orderkey
		and l_returnflag = 'R'
		and o_orderdate >= date '1993-08-01'
		and o_orderdate < date '1993-08-01' + interval '3' month
	group by
		o_custkey;

select
	c_name,
	c_address,
	n_name,
	c_phone,
	c_acctbal,
	c_comment,
	lost_revenue
from
	customer,
	nation,
	revenue_loss
where
	c_custkey = revenue_loss.c_custkey
	and c_nationkey = n_nationkey
order by
	lost_revenue desc
limit 20;

drop view revenue_loss;