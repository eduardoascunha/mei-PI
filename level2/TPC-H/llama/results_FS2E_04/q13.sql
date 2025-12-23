SELECT 
    c.cust_name, 
    COUNT(o.order_id) AS num_orders
FROM 
    customers c
LEFT JOIN 
    orders o ON c.cust_id = o.cust_id
WHERE 
    o.order_status = 'open'
    AND o.order_total > 1000
GROUP BY 
    c.cust_name
HAVING 
    COUNT(o.order_id) > 5;