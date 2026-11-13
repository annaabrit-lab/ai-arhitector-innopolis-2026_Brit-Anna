-- задание к уроку 10. Язык запросов SQL. Основные конструкции. Агрегация.
-- выполнил: Брит А.А.

-- задание 1
SELECT 
    customer_id,
    COUNT(payment_id) AS payment_count
FROM payment
GROUP BY customer_id
ORDER BY payment_count DESC;

-- задание 2
SELECT 
    customer_id,
    COUNT(payment_id) AS payment_count,
    CASE 
        WHEN COUNT(payment_id) > 30 THEN 1
        ELSE 0
    END AS frequent_payer
FROM payment
GROUP BY customer_id
ORDER BY payment_count DESC;


-- задание 3
SELECT 
    customer_id,
    SUM(amount) AS total_amount
FROM payment
GROUP BY customer_id
ORDER BY total_amount DESC;

-- задание 4
WITH customer_totals AS (
    SELECT 
        customer_id,
        SUM(amount) AS total_amount
    FROM payment
    GROUP BY customer_id
),
median_value AS (
    SELECT 
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_amount) AS median_total
    FROM customer_totals
)
SELECT 
    ct.customer_id,
    ct.total_amount,
    CASE 
        WHEN ct.total_amount > mv.median_total THEN 1
        ELSE 0
    END AS prospective_client
FROM customer_totals ct
CROSS JOIN median_value mv
ORDER BY ct.total_amount DESC;

-- медианное значение
WITH customer_totals AS (
    SELECT SUM(amount) AS total_amount
    FROM payment
    GROUP BY customer_id
)
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_amount) AS median_total
FROM customer_totals;