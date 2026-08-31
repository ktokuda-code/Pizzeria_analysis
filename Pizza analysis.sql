--Сезонность внутри дня
SELECT 
    hour,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(quantity::numeric * price::numeric), 2) AS revenue,
    ROUND(AVG(quantity::numeric * price::numeric), 2) AS avg_check
FROM clean_pizza_dataset
GROUP BY hour
ORDER BY hour;

--Эффективность размера пиццы
SELECT 
    name,
    size,
    SUM(quantity::numeric) AS total_sold,
    ROUND(SUM(quantity::numeric * price::numeric) / NULLIF(SUM(quantity::numeric), 0), 2) AS revenue_per_pizza
FROM clean_pizza_dataset
GROUP BY name, size
ORDER BY revenue_per_pizza DESC
LIMIT 10;

--Индекс повторных покупок (Loyalty Index)
SELECT 
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN quantity >= 3 THEN order_id END) / 
        NULLIF(COUNT(DISTINCT order_id), 0), 2
    ) AS family_order_percent
FROM clean_pizza_dataset;

--Самый дорогой час для пиццерии 
WITH filtered AS (
    SELECT 
        hour,
        order_id,
        SUM(quantity * price) AS order_total
    FROM clean_pizza_dataset
    GROUP BY hour, order_id
    HAVING SUM(quantity) <= 5)
SELECT 
    hour,
    ROUND(AVG(order_total::numeric), 2) AS avg_check
FROM filtered
GROUP BY hour
ORDER BY avg_check DESC
LIMIT 1;

--++Категорийный "перекресток"
SELECT 
    day_name,
    category,
    SUM(quantity::numeric) AS total_sold
FROM clean_pizza_dataset
WHERE category IN ('Veggie', 'Chicken')
GROUP BY day_name, category
ORDER BY day_name, category;

--Вклад ТОП-3 пицц в общую выручку (Concentration Index)
WITH total_revenue AS (
    SELECT SUM(quantity * price) AS total FROM clean_pizza_dataset
),
top3_revenue AS (
    SELECT SUM(quantity * price) AS top3_sum
    FROM clean_pizza_dataset
    WHERE name IN (
        SELECT name FROM clean_pizza_dataset
        GROUP BY name
        ORDER BY SUM(quantity * price) DESC
        LIMIT 3)
)
SELECT 
    ROUND(100.0 * top3_sum::numeric / total::numeric, 2) AS top3_concentration_percent
FROM top3_revenue, total_revenue;

--динамика размера по месяцам
SELECT 
    month_name,
    size,
    SUM(quantity) AS total_sold
FROM clean_pizza_dataset
GROUP BY month_name, size
ORDER BY month_name, size;