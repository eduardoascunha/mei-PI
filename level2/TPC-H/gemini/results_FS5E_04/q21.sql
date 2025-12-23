SELECT
	s_name,
	s_address
FROM
	supplier
JOIN
	nation ON s_nationkey = n_nationkey
WHERE
	n_name = 'ETHIOPIA'
	AND EXISTS (
		SELECT
			*
		FROM
			lineitem l1
		WHERE
			l1.l_suppkey = s_suppkey
			AND EXISTS (
				SELECT
					*
				FROM
					orders
				WHERE
					o_orderkey = l1.l_orderkey
					AND o_orderstatus = 'F'
			)
			AND l1.l_receiptdate > l1.l_commitdate
			AND EXISTS (
				SELECT
					*
				FROM
					lineitem l2
				WHERE
					l2.l_orderkey = l1.l_orderkey
					AND l2.l_suppkey <> l1.l_suppkey
			)
			AND NOT EXISTS (
				SELECT
					*
				FROM
					lineitem l3
				WHERE
					l3.l_orderkey = l1.l_orderkey
					AND l3.l_suppkey <> l1.l_suppkey
					AND l3.l_receiptdate > l3.l_commitdate
			)
	)
ORDER BY
	s_name
LIMIT 100;