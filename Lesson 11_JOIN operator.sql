-- задание к уроку 11. Язык запросов SQL. Операторы соединения. Оконные функции.
-- выполнила: Брит А.А.

-- ЗАДАНИЕ 1. Для каждого фильма количество уникальных клиентов, которые брали его в прокат

SELECT *
FROM film;
-- всего 1000 строк

SELECT 
    f.title AS film_title
    ,COUNT(DISTINCT r.customer_id) AS unique_customers
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title
ORDER BY unique_customers DESC;
-- 958 фильмов (958 строка - 4 уникальных клиента), значит 42 фильма никто не брал ни разу в прокат.

-- 42 фильма из 1000 (4.2% ассортимента) не приносят денег. 
-- посмотрим наименования этих фильмов

SELECT 
    f.title AS film_title
    ,COUNT(DISTINCT r.customer_id) AS unique_customers
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title
ORDER BY unique_customers ASC
LIMIT 50; -- оставила 50, чтобы проверить, что с 43 фильма начнется цифра 4.

-- Магазину, возможно, стоит списать их или заменить на другие, более востребованные.
-- почему 42 фильма не берут?
-- стоит посмотреть что это за фильмы и далее проанализировать почему эти фильмы не берут, возможно, по описанию, жанру, стоимости, наличию на складе и т.д.
-- смотрим гипотезы и проверяем каждую, делаем выводы.

SELECT *
FROM inventory;

-- гипотеза: отсутсвие на складе
SELECT 
    COUNT(f.film_id) AS total_films
    ,COUNT(i.inventory_id) AS films_with_inventory
    ,COUNT(f.film_id) - COUNT(i.inventory_id) AS films_without_inventory
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
WHERE f.title IN (
    'Gump Date', 'Catch Amistad', 'Pearl Destiny', 'Crossing Divorce', 
    'Firehouse Vietnam', 'Deliverance Mulholland', 'Treasure Command', 
    'Wake Jaws', 'Psycho Shrunk', 'Volume House', 'Hocus Frida', 
    'Walls Artist', 'Floats Garden', 'Roof Champion', 'Kill Brotherhood', 
    'Sky Miracle', 'Tadpole Park', 'Gladiator Westward', 'Hate Handicap', 
    'Order Betrayed', 'Villain Desperate', 'Perdition Fargo', 
    'Frankenstein Stranger', 'Rainbow Shock', 'Sister Freddy', 
    'Crystal Breaking', 'Alice Fantasia', 'Butch Panther', 'Chocolate Duck', 
    'Dazed Punk', 'Commandments Express', 'Apollo Teen', 'Kentuckian Giant', 
    'Raiders Antitrust', 'Argonauts Town', 'Suicides Silence', 
    'Ark Ridgemont', 'Chinatown Gladiator', 'Crowds Telemark', 
    'Arsenic Independence', 'Boondock Ballroom', 'Muppet Mile'
);
-- Вывод: гипотеза подтвердилась, 42 фильма отсутствуют в магазинах.
-- Рекомендации: либо закупить, либо удалить из БД.

-- в таблице inventory ровно 1000 строк. Почему? должно быть 958.
-- проверим расчет
SELECT 
    f.film_id,
    f.title,
    COUNT(i.inventory_id) AS copies_on_shelf
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
WHERE f.title IN (
    'Gump Date', 'Catch Amistad', 'Pearl Destiny', 'Crossing Divorce', 
    'Firehouse Vietnam', 'Deliverance Mulholland', 'Treasure Command', 
    'Wake Jaws', 'Psycho Shrunk', 'Volume House', 'Hocus Frida', 
    'Walls Artist', 'Floats Garden', 'Roof Champion', 'Kill Brotherhood', 
    'Sky Miracle', 'Tadpole Park', 'Gladiator Westward', 'Hate Handicap', 
    'Order Betrayed', 'Villain Desperate', 'Perdition Fargo', 
    'Frankenstein Stranger', 'Rainbow Shock', 'Sister Freddy', 
    'Crystal Breaking', 'Alice Fantasia', 'Butch Panther', 'Chocolate Duck', 
    'Dazed Punk', 'Commandments Express', 'Apollo Teen', 'Kentuckian Giant', 
    'Raiders Antitrust', 'Argonauts Town', 'Suicides Silence', 
    'Ark Ridgemont', 'Chinatown Gladiator', 'Crowds Telemark', 
    'Arsenic Independence', 'Boondock Ballroom', 'Muppet Mile'
)
GROUP BY f.film_id, f.title
ORDER BY copies_on_shelf;

-- в колонке film_id есть значения, которые совпадают, 
-- т.е. один и тот же фильм может иметь несколько копий.


-- ЗАДАНИЕ 2. Для каждого фильма рассчитать сумму денег, которую он принес.

SELECT 
    f.title AS film_title
    ,SUM(p.amount) AS total_revenue
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY f.film_id, f.title
ORDER BY total_revenue DESC;
-- Размах от 215.75 до 5.94
-- т.к. 42 фильмов нет в магазине, то и учитывать их при суммарном значении не имеет смысла.

-- если нужно использовать эти данные, то  COALESCE(SUM(p.amount), 0)
SELECT 
    f.title AS film_title,
    COALESCE(SUM(p.amount), 0) AS total_revenue
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
LEFT JOIN payment p ON r.rental_id = p.rental_id
GROUP BY f.film_id, f.title
ORDER BY total_revenue DESC;
WITH customer_totals AS (
    SELECT SUM(amount) AS total_amount
    FROM payment
    GROUP BY customer_id
)
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_amount) AS median_total
FROM customer_totals;

-- ЗАДАНИЕ 3. Расчитайте для каждого фильма среднюю продолжительность проката

SELECT 
    f.title AS film_title,
    ROUND(AVG(EXTRACT(EPOCH FROM (r.return_date - r.rental_date)) / 86400), 2) AS avg_rental_days
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.return_date IS NOT NULL
GROUP BY f.film_id, f.title
ORDER BY avg_rental_days DESC;

-- результат: от 2 суток до 8, если округлить в большую сторону

-- ЗАДАНИЕ 4.  Расчитайте для каждого фильма долю просроченных прокатов

SELECT 
    f.title AS film_title,
    COUNT(r.rental_id) AS total_rentals,
    SUM(CASE 
            WHEN r.return_date > (r.rental_date + (f.rental_duration || ' days')::interval) 
            THEN 1 ELSE 0 
        END) AS overdue_rentals,
    ROUND(
        SUM(CASE 
                WHEN r.return_date > (r.rental_date + (f.rental_duration || ' days')::interval) 
                THEN 1 ELSE 0 
            END)::numeric / COUNT(r.rental_id) * 100, 2
    ) AS overdue_percentage
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.return_date IS NOT NULL
GROUP BY f.film_id, f.title, f.rental_duration
ORDER BY overdue_percentage DESC;

-- ЗАДАНИЕ 5.  Расчитайте для каждого фильма количество клиентов, которые повторно брали в прокат фильм
WITH customer_rentals AS (
    SELECT 
        f.title AS film_title,
        r.customer_id,
        COUNT(r.rental_id) AS rent_count
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY f.title, r.customer_id
)
SELECT 
    film_title,
    COUNT(customer_id) AS repeat_customers_count
FROM customer_rentals
WHERE rent_count >= 2
GROUP BY film_title
ORDER BY repeat_customers_count DESC;

-- интересно, есть ли клиенты, которые берут несколько фильмов повторно
SELECT 
    r.customer_id,
    f.title AS film_title,
    COUNT(r.rental_id) AS rent_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY r.customer_id, f.title
HAVING COUNT(r.rental_id) >= 2
ORDER BY r.customer_id, rent_count DESC;

-- такие есть, сгруппируем данные: посмотрим сколько фильмов пересматривали клиенты

WITH repeat_rentals AS (
    SELECT 
        r.customer_id,
        f.film_id,
        COUNT(r.rental_id) AS rent_count
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY r.customer_id, f.film_id
    HAVING COUNT(r.rental_id) >= 2
)
SELECT 
    customer_id,
    COUNT(film_id) AS movies_watched_twice_or_more
FROM repeat_rentals
GROUP BY customer_id
ORDER BY movies_watched_twice_or_more DESC;

-- более 2 фильмов пересматривало 28 человек, из них 1 человек - 4 фильиа, два - 3 фильма, 25 человек - 2 фильма.
-- не такое большое количество людей, пересматривающих различные фильмы многократно.
-- можно предложить им персональную скидку на повторный просмотр фильмов. 