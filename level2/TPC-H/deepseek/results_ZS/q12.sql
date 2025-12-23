SELECT l_shipmode,
       SUM(CASE WHEN o_orderpriority = '1-URGENT' OR o_orderpriority = '2-HIGH' THEN 1 ELSE 0 END) AS high_priority_count,
       SUM(CASE WHEN o_orderpriority <> '1-URGENT' AND o_orderpriority <> '2-HIGH' THEN 1 ELSE 0 END) AS low_priority_count
FROM lineitem
JOIN orders ON l_orderkey = o_orderkey
WHERE l_shipmode IN ('FOB', 'MAIL')
  AND l_receiptdate > l_commitdate
  AND l_shipdate < l_commitdate
  AND l_receiptdate >= '1996-01-01'
  AND l_receiptdate < '1997-01-01'
GROUP BY l_shipmode
ORDER BY l_shipmode;