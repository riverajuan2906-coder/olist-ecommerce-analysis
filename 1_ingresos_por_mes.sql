SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS mes,
    SUM(p.payment_value) AS ingresos_totales,
    COUNT(DISTINCT o.order_id) AS total_ordenes
FROM ordenes o
JOIN pagos p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY mes
ORDER BY mes;