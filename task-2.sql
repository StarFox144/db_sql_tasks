--Запити на вибірку даних 
Отримання списку фільмів та їх категорій
SELECT 
    film.title AS "Назва фільму",
    film.length AS "Тривалість",
    category.name AS "Категорія"
FROM film
INNER JOIN film_category ON film.film_id = film_category.film_id
INNER JOIN category ON film_category.category_id = category.category_id
ORDER BY film.title;

Фільми, орендовані певним клієнтом
SELECT 
    customer.first_name AS "Ім'я",
    customer.last_name AS "Прізвище",
    film.title AS "Назва фільму",
    rental.rental_date AS "Дата оренди",
    rental.return_date AS "Дата повернення"
FROM rental
INNER JOIN customer ON rental.customer_id = customer.customer_id
INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
INNER JOIN film ON inventory.film_id = film.film_id
WHERE customer.customer_id = 1  -- Тут можна змінити ID клієнта
ORDER BY rental.rental_date DESC;

Популярність фільмів
SELECT 
    f.title AS "Назва фільму",
    COUNT(r.rental_id) AS "Кількість оренд",
    f.rental_rate AS "Вартість оренди",
    c.name AS "Категорія"
FROM film f
INNER JOIN inventory i ON f.film_id = i.film_id
INNER JOIN rental r ON i.inventory_id = r.inventory_id
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
GROUP BY f.film_id, f.title, f.rental_rate, c.name
ORDER BY "Кількість оренд" DESC
LIMIT 5;

--Маніпуляції з даними
Додавання нового клієнта
-- Спочатку додаємо запис в таблицю address
INSERT INTO address (
    address,
    district,
    city_id,
    postal_code,
    phone
)
VALUES (
    '123 Main St',
    'California',
    (SELECT city_id FROM city WHERE city = 'San Francisco' LIMIT 1),
    '94105',
    ''
)
RETURNING address_id;

-- Потім додаємо запис в таблицю customer
INSERT INTO customer (
    store_id,
    first_name,
    last_name,
    email,
    address_id,
    active
)
VALUES (
    1,  -- Припускаємо, що store_id = 1 існує
    'Alice',
    'Cooper',
    'alice.cooper@example.com',
    (SELECT address_id FROM address WHERE address = '123 Main St' ORDER BY address_id DESC LIMIT 1),
    1
);
Оновлення адреси клієнта
-- Оновлення існуючого запису в таблиці address
UPDATE address
SET address = '456 Elm St'
WHERE address_id = (
    SELECT address_id 
    FROM customer 
    WHERE first_name = 'Alice' 
    AND last_name = 'Cooper'
);
-- Потім оновлюємо посилання на адресу в таблиці customer
UPDATE customer
SET address_id = (
    SELECT address_id 
    FROM address 
    WHERE address = '456 Elm St' 
    ORDER BY address_id DESC 
    LIMIT 1
)
WHERE first_name = 'Alice' 
AND last_name = 'Cooper';

Видалення клієнта
-- Спочатку зберігаємо ID клієнта та адреси для подальшого використання
WITH customer_info AS (
    SELECT customer_id, address_id
    FROM customer
    WHERE first_name = 'Alice' 
    AND last_name = 'Cooper'
)

-- Видаляємо пов'язані записи про оплату
DELETE FROM payment 
WHERE customer_id = (SELECT customer_id FROM customer_info);

-- Видаляємо записи про оренду
DELETE FROM rental 
WHERE customer_id = (SELECT customer_id FROM customer_info);

-- Видаляємо запис про клієнта
DELETE FROM customer 
WHERE customer_id = (SELECT customer_id FROM customer_info);

-- Опціонально: видаляємо адресу, якщо вона більше не використовується
DELETE FROM address 
WHERE address_id = (SELECT address_id FROM customer_info)
AND NOT EXISTS (
    SELECT 1 
    FROM customer 
    WHERE customer.address_id = address.address_id
);
