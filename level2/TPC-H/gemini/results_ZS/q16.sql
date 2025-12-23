SELECT
  p.p_brand,
  p.p_type,
  p.p_size,
  count(DISTINCT ps.ps_suppkey) AS supplier_cnt
FROM
  partsupp AS ps
JOIN
  part AS p
  ON p.p_partkey = ps.ps_partkey
WHERE
  p.p_brand <> 'Brand#42'
  AND p.p_type NOT LIKE 'LARGE PLATED%'
  AND p.p_size IN (9, 7, 14, 41, 43, 38, 23, 34)
  AND ps.ps_suppkey NOT IN (
    SELECT
      s.s_suppkey
    FROM
      supplier AS s
    WHERE
      s.s_comment LIKE '%Customer%Complaints%'
  )
GROUP BY
  p.p_brand,
  p.p_type,
  p.p_size
ORDER BY
  supplier_cnt DESC,
  p.p_brand,
  p.p_type,
  p.p_size;