# Olist E-Commerce Analysis
### SQL + Power BI | Proyecto de Portafolio análisis de empresa de e-commerce

Análisis de más de 100,000 órdenes reales de Olist, el mercado de comercio electrónico (*marketplace*) más grande de Brasil, utilizando PostgreSQL para la consulta de datos y Power BI para los tableros de inteligencia de negocios.

### Vista Previa del Dashboard
<img width="551" height="311" alt="dashboard Olist completo " src="https://github.com/user-attachments/assets/56143516-d8fd-4c24-97b1-0abadb03aa56" />
<img width="614" height="181" alt="KPIS y tendencia" src="https://github.com/user-attachments/assets/0d9605a5-180c-46bb-911b-33841a9e9694" />
<img width="593" height="165" alt="vendedores y logistica" src="https://github.com/user-attachments/assets/83e935f5-8779-4ff4-aaa6-09da1f35a819" />

### Objetivo del Negocio
Este proyecto responde a tres preguntas fundamentales para cualquier negocio de comercio electrónico:

* **¿Dónde está el dinero?** — Qué categorías de productos y qué vendedores generan la mayor cantidad de ingresos.
* **¿Qué tan bien está funcionando la operación?** — Rendimiento de las entregas frente a las expectativas del cliente.
* **¿Qué tan satisfechos están los clientes?** — Calificaciones de reseñas por categoría y por vendedor.

### Conjunto de Datos (Dataset)
* **Fuente:** [Brazilian E-Commerce Public Dataset by Olist — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
* **Cobertura:** Septiembre 2016 – Octubre 2018 | Brasil

| Tabla | Descripción |
| :--- | :--- |
| **ordenes** | Tabla principal de órdenes con estados y marcas de tiempo (*timestamps*). |
| **orden_items** | Productos individuales por orden con precio y costo de envío. |
| **pagos** | Método de pago y valor pagado por orden. |
| **reviews** | Calificaciones de reseñas de clientes y comentarios. |
| **clientes** | Ubicación del cliente e identificadores únicos. |
| **vendedores** | Ubicación del vendedor e identificador. |
| **productos** | Categoría del producto y dimensiones. |

### Estructura del Proyecto

```text
olist-ecommerce-analysis/
├── queries/
│   ├── 01_ingresos_por_mes.sql
│   ├── 02_top_categorias.sql
│   ├── 03_estado_ordenes.sql
│   ├── 04_calificacion_por_categoria.sql
│   ├── 05_tiempo_entrega.sql
│   └── 06_top_vendedores.sql
├── dashboard/
│   ├── e-commerce.pbix
│   └── capturas/
│       ├── 01_dashboard_completo.png
│       ├── 02_kpis_y_tendencia.png
│       └── 03_vendedores_y_logistica.png
└── README.md
```
---

## Análisis en SQL
 
Todas las consultas fueron escritas en PostgreSQL. Cada consulta responde a una pregunta de negocio específica.
 
### Consulta 01 — Tendencia de Ingresos Mensuales
**Pregunta de negocio:** ¿Cómo han evolucionado los ingresos a lo largo del tiempo? ¿Existen patrones estacionales?
 
```sql
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS mes,
    ROUND(SUM(p.payment_value)::numeric, 2) AS ingresos_totales,
    COUNT(DISTINCT o.order_id) AS total_ordenes
FROM ordenes o
JOIN pagos p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY mes
ORDER BY mes;
```

> Se utilizó `payment_value` de la tabla de pagos en lugar de `price` de la tabla order_items porque refleja el monto real pagado por el cliente, incluyendo descuentos y múltiples métodos de pago.

---

### Consulta 02 — Top 10 Categorías por Ingresos
**Pregunta de negocio:** ¿Qué categorías de productos generan la mayor cantidad de ingresos?
 
```sql
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
```
 
---
 
### Consulta 03 — Distribución del Estado de las Órdenes
**Pregunta de negocio:** ¿Qué porcentaje de órdenes se entregan con éxito frente a las que se cancelan?
 
```sql
SELECT 
    order_status AS estado,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS porcentaje
FROM ordenes
GROUP BY order_status
ORDER BY total DESC;
```
> Utiliza una función de ventana (`SUM OVER()`) para calcular el porcentaje de cada estado respecto al total sin necesidad de una subconsulta.
 
---
 
### Consulta 04 — Calificación Promedio por Categoría
**Pregunta de negocio:** ¿Qué categorías tienen los clientes más satisfechos (y los menos satisfechos)?
 
```sql
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
```
> El filtro `HAVING COUNT >= 50` descarta las categorías con muy pocas reseñas para garantizar promedios estadísticamente significativos. 
 
---
 
### Consulta 05 — Tiempo Promedio de Entrega
**Pregunta de negocio:**¿Cuántos días toma una entrega en promedio y si Olist entrega antes o después de la fecha estimada?
 
```sql
SELECT 
    ROUND(AVG(
        EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp))
    )::numeric, 1) AS dias_promedio_entrega,
    ROUND(AVG(
        EXTRACT(DAY FROM (order_estimated_delivery_date - order_delivered_customer_date))
    )::numeric, 1) AS dias_antes_estimado
FROM ordenes
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
```
---
 
### Consulta 06 — Top 10 Vendedores por Ingresos y Calificación
**Pregunta de negocio:** ¿Quiénes son los vendedores con mayores ingresos y si son también los mejor calificados?
 
```sql
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
```
 
---
 
## Dashboard en Power BI
 
El tablero se construyó conectando Power BI Desktop directamente a PostgreSQL e incluye los siguientes elementos visuales:
 
- **3 Tarjetas de KPI** — Ingresos totales (solo órdenes entregadas), total de órdenes y calificación promedio de reseñas.
- **Gráfico de líneas** — Tendencia de ingresos mensuales desde octubre de 2016 hasta agosto de 2018.
- **Gráfico de barras horizontales** — Top 10 categorías de productos por ingresos.
- **Gráfico de dona** — Distribución del estado de las órdenes.
- **Gráfico de barras horizontales** — Top categorías por calificación promedio de los clientes.
- **Tarjetas de KPI** — Tiempo promedio de entrega y días de anticipación respecto a la fecha estimada.
- **Tabla** — Top 10 vendedores ordenados por ingresos, incluyendo su calificación y conteo de órdenes.

---
 
## Conclusiones Clave
-**Crecimiento sostenido:** El comercio electrónico en Olist experimentó un crecimiento exponencial entre 2017 y 2018, consolidando el volumen de ventas mes a mes.
-**El impacto del Black Friday (Estacionalidad):** Noviembre de 2017 registra un pico histórico masivo en ingresos totales y número de órdenes debido al impacto directo del Black Friday, siendo el mes más fuerte de todo el periodo analizado.
-**Estabilización de ingresos:** Durante 2018, el negocio logró estabilizar un piso de ingresos mensuales significativamente más alto que el del año anterior, manteniendo una consistencia en el volumen de órdenes entregadas.
- **beleza_saude (belleza y salud)** es la categoría líder en ingresos con $1.42 mill., seguida por relojes y artículos de cama/mesa/baño.
- **El 97% de las órdenes se entregan con éxito**, con una tasa de cancelación de apenas el 0.6%, lo que demuestra un sólido rendimiento operativo.
**Estrategia Comercial de Entrega (Expectativa vs. Realidad):** La plataforma Olist maneja una política muy conservadora en sus promesas de envío, mostrando al cliente una **fecha estimada promedio de 24.5 días**. Sin embargo, la operación logística real es altamente eficiente y entrega los pedidos en un **tiempo real promedio de 12.5 días**, logrando una anticipación de casi 12 días respecto a lo prometido. +
- Categorías como **cds_dvds_musicais** y **livros_interesse_geral** cuentan con las calificaciones más altas por parte de los clientes (4.5+).
- **Concentración Geográfica de Vendedores:** Los vendedores con mayores ingresos se concentran fuertemente en el estado de **São Paulo**. Municipios como **Guariba, Ibitinga e Itaquaquecetuba** (ubicada en la región metropolitana del Gran São Paulo) lideran el ranking comercial, logrando sostener calificaciones promedio muy competitivas de entre 3.5 y 4.2 puntos. Esto confirma que el motor principal de este ecosistema de e-commerce se encuentra centralizado en la región del sureste brasileño.

---
 
## Herramientas utilizadas
 
- **PostgreSQL 18** — Base de datos relacional y consultas SQL.
- **pgAdmin 4** — Gestión de base de datos y ejecución de consultas.
- **Power BI Desktop** — Modelado de datos y visualización en dashboards.
- **GitHub** — Control de versiones y publicación del portafolio.

---
 
## Como ejecutar
 
1. Instala PostgreSQL y pgAdmin.
2. Descarga una base de datos llamada `ecommerce_db`
3. Importa los 7 archivos CSV del conjunto de datos de Olist Kaggle dataset. [Olist Kaggle dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
4. Ejecuta en orden los archivos SQL que se encuentran dentro de la carpeta `queries/`. 
5. Abre `e-commerce.pbix` en Power BI Desktop y actualiza las credenciales de la conexión a PostgreSQL para apuntar a tu servidor local.

