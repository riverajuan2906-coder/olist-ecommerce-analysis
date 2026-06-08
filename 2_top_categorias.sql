SELECT 
    pr.product_category_name AS categoria,
    ROUND(SUM(p.payment_value)::numeric, 2) AS ingresos,
    COUNT(DISTINCT o.order_id) AS ordenes
FROM ordenes o
JOIN orden_items oi ON o.order_id = oi.order_id
JOIN productos pr ON oi.product_id = pr.product_id
JOIN pagos p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND pr.product_category_name IS NOT NULL
GROUP BY categoria
ORDER BY ingresos DESC
LIMIT 10;