-- Задание 2.2.5. Язык запросов SQL. Индексация. Нагрузочное тестирование
-- Брит Анна

-- Сформулируйте любую интересующую вас практическую задачу и на ее основе по данным dvdrental создайте 
-- запрос, отвечающий следующим требованиям:
-- • Хотя бы два JOIN
-- • Хотя бы одно использование GROUP BY
-- • Хотя бы один CASE
-- • Хотя бы один WHERE
-- • Хотя бы одна оконная функци

-- Формулировка задачи:
-- Найти фильмы, которые чаще всего задерживают, и показать их рейтинг

SELECT 
    f.title AS film_title,
    COUNT(r.rental_id) AS total_rentals,
    
    -- CASE: считаем количество просрочек
    SUM(CASE 
            WHEN r.return_date > (r.rental_date + (f.rental_duration || ' days')::interval) 
            THEN 1 
            ELSE 0 
        END) AS overdue_rentals,
        
    -- Оконная функция: вычисляем долю просрочки и присваиваем рейтинг (ранг)
    RANK() OVER (
        ORDER BY SUM(CASE 
                        WHEN r.return_date > (r.rental_date + (f.rental_duration || ' days')::interval) 
                        THEN 1 
                        ELSE 0 
                     END)::numeric / COUNT(r.rental_id) DESC
    ) AS overdue_rank

FROM film f
-- JOIN 1: Соединяем с копиями на складе
JOIN inventory i ON f.film_id = i.film_id
-- JOIN 2: Соединяем с прокатами
JOIN rental r ON i.inventory_id = r.inventory_id

-- WHERE: Берем только завершенные прокаты (где есть дата возврата)
WHERE r.return_date IS NOT NULL

-- GROUP BY: Группируем по фильмам и их сроку аренды
GROUP BY f.film_id, f.title, f.rental_duration

-- Сортируем по убыванию процента просрочки, чтобы наверху были самые "проблемные" фильмы
ORDER BY overdue_rank;

-- 958 фильмов показано, что соответствует выводам по предыдущей задаче, о том, что 42 фильма отсутсвуют на складе.
-- из 958 с задержкой хотя бы 1 раз задерживали 952 фильма, т.е клиенты достаточно часто задерживают фильмы.
-- получается просрочка аренды - это не исключение, а норма. 
-- возможно стоит задуматься об изменениях в условии аренды, автоматической рассылки напоминайний и т.д.

-- можно посомтреть по каким причинам происходит задержка.
-- например, посмотрим зависимость просрочек от срока аренды (3-7 дней)
SELECT 
    f.rental_duration AS rental_days,
    COUNT(r.rental_id) AS total_rentals,
    SUM(CASE 
            WHEN r.return_date > (r.rental_date + (f.rental_duration || ' days')::interval) 
            THEN 1 ELSE 0 
        END) AS overdue_count,
    ROUND(
        SUM(CASE 
                WHEN r.return_date > (r.rental_date + (f.rental_duration || ' days')::interval) 
                THEN 1 ELSE 0 
            END)::numeric / COUNT(r.rental_id) * 100, 1
    ) AS overdue_percent
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.return_date IS NOT NULL
GROUP BY f.rental_duration
ORDER BY f.rental_duration;

-- вывод: Когда магазин дает всего 3 дня, 
-- клиенты видимо не успевают посмотреть фильм, и 72% из них опаздывают. 
-- Когда дают 7 дней — опаздывают в 2.5 раза реже (29%).


-- далее можно посмотреть: насколько сильно задерживают
WITH overdue_stats AS (
    SELECT 
        f.title,
        r.rental_date,
        r.return_date,
        f.rental_duration,
        -- Вычисляем, на сколько дней опоздали
        EXTRACT(DAY FROM (r.return_date - (r.rental_date + (f.rental_duration || ' days')::interval))) AS days_late
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE r.return_date IS NOT NULL
),
categorized_stats AS (
    -- Создаем второй черновик, где используем CASE
    SELECT 
        CASE 
            WHEN days_late <= 0 THEN 'Вовремя'
            WHEN days_late <= 2 THEN '1-2 дня'
            WHEN days_late <= 5 THEN '3-5 дней'
            WHEN days_late <= 10 THEN '6-10 дней'
            ELSE 'Более 10 дней'
        END AS late_category
    FROM overdue_stats
)
-- Теперь в основном запросе late_category уже существует
SELECT 
    late_category,
    COUNT(*) AS rental_count
FROM categorized_stats
GROUP BY late_category
ORDER BY 
    CASE late_category
        WHEN 'Вовремя' THEN 1
        WHEN '1-2 дня' THEN 2
        WHEN '3-5 дней' THEN 3
        WHEN '6-10 дней' THEN 4
        ELSE 5
    END;

-- выводы: Большинство опозданий — это 1-2 дня (3 482 случая) 
-- и 3-5 дней (2 726 случаев
-- большая часть прокатов возвращается вовремя (9 458 случаев)
-- и незначительная часть с задержкой на 6-10 суток (195 случаев)

-- добавим таблицу с процентом задержек по категориям (количество дней)

WITH overdue_stats AS (
    SELECT 
        f.title,
        r.rental_date,
        r.return_date,
        f.rental_duration,
        EXTRACT(DAY FROM (r.return_date - (r.rental_date + (f.rental_duration || ' days')::interval))) AS days_late
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE r.return_date IS NOT NULL
),
categorized_stats AS (
    SELECT 
        CASE 
            WHEN days_late <= 0 THEN 'Вовремя'
            WHEN days_late <= 2 THEN '1-2 дня'
            WHEN days_late <= 5 THEN '3-5 дней'
            WHEN days_late <= 10 THEN '6-10 дней'
            ELSE 'Более 10 дней'
        END AS late_category
    FROM overdue_stats
)
SELECT 
    late_category AS "Категория задержки",
    COUNT(*) AS "Количество прокатов",
    -- Расчет процента (делим на общее количество с помощью оконной функции)
    ROUND(COUNT(*)::numeric * 100 / SUM(COUNT(*)) OVER (), 2) AS "Процент"
FROM categorized_stats
GROUP BY late_category
ORDER BY 
    CASE late_category
        WHEN 'Вовремя' THEN 1
        WHEN '1-2 дня' THEN 2
        WHEN '3-5 дней' THEN 3
        WHEN '6-10 дней' THEN 4
        ELSE 5
    END;

-- общий вывод: стоит увеличить срок аренды и ввести напоминанию об истекащем сроке/возможности продления и т.д.