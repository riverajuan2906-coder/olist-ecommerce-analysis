SELECT 
    v.seller_id,
    v.seller_city AS ciudad,
    ROUND(SUM(p.payment_value)::numeric, 2) AS ingresos_totales,
    ROUND(AVG(r.review_score)::numeric, 2) AS calificacion_promedio,
    COUNT(DISTINCT o.order_id) AS ordenes
FROM vendedores v
JOIN orden_items oi ON v.seller_id = oi.seller_id
JOIN ordenes o ON oi.order_id = o.order_id
JOIN pagos p ON o.order_id = p.order_id
JOIN reviews r ON o.order_id = r.order_id
GROUP BY v.seller_id, v.seller_city
HAVING COUNT(DISTINCT o.order_id) >= 20
ORDER BY ingresos_totales DESC
LIMIT 10;