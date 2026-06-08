SELECT 
    ROUND(AVG(
        EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)))::numeric, 1) AS dias_promedio_entrega,
    ROUND(AVG(EXTRACT(DAY FROM (order_estimated_delivery_date - order_delivered_customer_date)))::numeric, 1) AS dias_antes_estimado
FROM ordenes
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;