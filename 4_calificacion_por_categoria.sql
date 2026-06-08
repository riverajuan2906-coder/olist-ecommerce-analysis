SELECT 
    pr.product_category_name AS categoria,
    ROUND(AVG(r.review_score)::numeric, 2) AS calificacion_promedio,
    COUNT(r.review_id) AS total_reviews
FROM reviews r
JOIN ordenes o ON r.order_id = o.order_id
JOIN orden_items oi ON o.order_id = oi.order_id
JOIN productos pr ON oi.product_id = pr.product_id
WHERE pr.product_category_name IS NOT NULL
GROUP BY categoria
HAVING COUNT(r.review_id) >= 50
ORDER BY calificacion_promedio DESC
LIMIT 10;