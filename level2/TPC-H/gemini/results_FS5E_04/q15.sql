WITH revenue0 AS (
	SELECT
		l_suppkey AS supplier_no,
		SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
	FROM
		lineitem
	WHERE
		l_shipdate >= DATE '1997-01-01'
		AND l_shipdate < DATE '1997-01-01' + INTERVAL '3' MONTH
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
	supplier s,
	revenue0 r
WHERE
	s.s_suppkey = r.supplier_no
	AND r.total_revenue = (
		SELECT
			MAX(total_revenue)
		FROM
			revenue0
	)
ORDER BY
	s.s_suppkey;