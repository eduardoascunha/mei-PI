WITH 
    total_value AS (
        SELECT 
            l_partkey, 
            SUM(l_quantity * l_extendedprice) AS total_value
        FROM 
            lineitem
        GROUP BY 
            l_partkey
    ),
    ranked_parts AS (
        SELECT 
            l_partkey, 
            ROW_NUMBER() OVER (ORDER BY total_value DESC) AS rank
        FROM 
            total_value
    ),
    significant_parts AS (
        SELECT 
            l_partkey
        FROM 
            ranked_parts
        WHERE 
            rank <= 0.0001 * (SELECT COUNT(*) FROM ranked_parts)
    )
SELECT 
    l_partkey
FROM 
    lineitem
WHERE 
    l_partkey IN (SELECT l_partkey FROM significant_parts)
AND 
    l_extendedprice > 0
GROUP BY 
    l_partkey
HAVING 
    SUM(l_extendedprice * l_quantity) > 0.0001 * (SELECT SUM(l_extendedprice * l_quantity) FROM lineitem)
ORDER BY 
    l_extendedprice DESC;