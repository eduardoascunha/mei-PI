WITH revenue_per_supplier AS (
  SELECT
    l_suppkey,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
  FROM
    lineitem
  WHERE
    l_shipdate >= DATE '1997-01-01'
    AND l_shipdate < DATE '1997-01-01' + INTERVAL '3 month'
  GROUP BY
    l_suppkey
)
SELECT
  s.s_suppkey,
  s.s_name,
  s.s_address,
  s.s_phone,
  r.total_revenue
FROM
  supplier AS s
JOIN
  revenue_per_supplier AS r
  ON s.s_suppkey = r.l_suppkey
WHERE
  r.total_revenue = (
    SELECT
      MAX(total_revenue)
    FROM
      revenue_per_supplier
  )
ORDER BY
  s.s_suppkey;