SELECT 
  l.supp_nation, 
  sum(l.extendedprice * (1 - l.discount)) AS total_revenue
FROM 
  (
    SELECT 
      l.orderkey, 
      l.partkey, 
      l_receiptdate, 
      l_extendedprice, 
      l_discount, 
      l.linenumber 
    FROM 
      lineitem 
    WHERE 
      l_receiptdate >= '1995-01-01' 
      AND l_receiptdate < '1996-01-01'
  ) l 
  JOIN (
    SELECT 
      o_orderkey, 
      o_orderdate 
    FROM 
      orders 
    WHERE 
      o_orderdate >= '1995-01-01' 
      AND o_orderdate < '1996-01-01'
  ) o ON l.orderkey = o.orderkey
JOIN (
  SELECT 
    s_nationkey, 
    s_name 
  FROM 
    supplier 
  WHERE 
    s_nationkey = 'KENYA'
) s ON l.supp_nationkey = s.s_nationkey
WHERE 
  l.supp_nationkey = 'KENYA'
GROUP BY 
  l.supp_nationkey;