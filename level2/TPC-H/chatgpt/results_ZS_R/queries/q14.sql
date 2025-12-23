SELECT
SUM(CASE WHEN p.p_type LIKE 'PROMO%' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) * 100.0 /
SUM(l.l_extendedprice * (1 - l.l_discount)) AS promo_revenue_percentage
FROM
lineitem l
JOIN
part p ON l.l_partkey = p.p_partkey
WHERE
l.l_shipdate >= DATE '1996-04-01'
AND l.l_shipdate < DATE '1996-05-01';
