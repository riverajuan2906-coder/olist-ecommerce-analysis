SELECT 
    order_status AS estado,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS porcentaje
FROM ordenes
GROUP BY order_status
ORDER BY total DESC;