--Total Revenue generated
SELECT SUM(amount) AS total_revenue 
FROM payment ;

--Total number of rentals per store
SELECT s.store_id, COUNT(r.rental_id) AS total_rentals
FROM rental r
JOIN staff s ON s.staff_id = r.staff_id
GROUP BY s.store_id
ORDER BY total_rentals DESC ;

--Top 10 most rented movies
SELECT f.film_id, f.title, COUNT(r.rental_id) AS rental_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10 ;

--Revenue by film category
SELECT c.category_id, c.name, SUM(p.amount) AS total_revenue
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY 1,2
ORDER BY 3 DESC ;

--Average rental duration by category
SELECT c.name, ROUND(AVG(f.rental_duration),2) AS avg_rental_duration
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
GROUP BY 1
ORDER BY 2 DESC ;

--Top 5 customers by total spending
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customers, 
SUM(p.amount) AS total_spending
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5 ;

--Monthly revenue trend
SELECT EXTRACT(YEAR FROM payment_date) AS  year, 
EXTRACT(MONTH FROM payment_date) AS month_number, 
TO_CHAR(payment_date, 'Month') AS month, 
SUM(amount) AS monthly_revenue
FROM payment 
GROUP BY 1,2,3
ORDER BY 1,2 ;

--category wise rank by revenue
SELECT c.name, SUM(p.amount) AS total_revenue,
RANK() OVER(ORDER BY SUM(p.amount) DESC) AS category_rank
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY 1 ;

--Top 5 customers by spending per store
WITH customer_spending AS( 
SELECT s.store_id, c.customer_id, c.first_name || ' ' || c.last_name AS customer_name, 
SUM(p.amount) AS total_spending,
RANK() OVER(PARTITION BY s.store_id ORDER BY SUM(p.amount) DESC) AS customer_ranking
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id 
JOIN customer c ON r.customer_id = c.customer_id
JOIN staff s ON r.staff_id = s.staff_id
GROUP BY 1,2,3
)
SELECT store_id, customer_id, customer_name, total_spending, customer_ranking 
FROM customer_spending
WHERE customer_ranking <=5 ;

--total spend by customer_id 148 per store
SELECT  
CASE WHEN staff_id = 1 THEN 'store_1'
ELSE 'store_2'
END AS store_id,
SUM(amount) AS total_spending
FROM payment
WHERE customer_id = 148
GROUP BY store_id ;

--films never rented
SELECT f.film_id, f.title 
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL ;

--Find repeat customers rented 40 or more times
SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS rental_count
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
GROUP BY 1,2,3
HAVING COUNT(r.rental_id) >=40
ORDER BY 4 DESC ;

--Highest revenue generating staff_member
SELECT s.staff_id, s.first_name, s.last_name, SUM(p.amount) AS total_revenue 
FROM payment p
JOIN staff s ON p.staff_id = s.staff_id
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 1 ;

--Top 5 films by revenue per store
WITH store_revenue AS (
SELECT s.store_id, f.film_id, f.title, SUM(p.amount) AS total_revenue,
RANK() OVER(PARTITION BY s.store_id ORDER BY SUM(p.amount) DESC) AS rank
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN staff s ON r.staff_id = s.staff_id
GROUP BY 1,2,3
)
SELECT store_id, title, total_revenue, rank 
FROM store_revenue
WHERE rank <=5 ;

--Revenue split percentage by film rating
WITH revenue_rating AS(
SELECT f.rating, SUM(p.amount) AS revenue_per_rating,
SUM(SUM(p.amount)) OVER() AS total_revenue 
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
GROUP BY 1
)
SELECT rating, revenue_per_rating, total_revenue, 
ROUND((revenue_per_rating/total_revenue)*100,2) AS revenue_percentage
FROM revenue_rating
ORDER BY revenue_percentage DESC

--Daily rentals in the first week of July 2005
SELECT DATE(rental_date) AS rental_day, COUNT(rental_id) AS daily_rentals
FROM rental
WHERE rental_date >= '2005-07-01' AND 
rental_date < '2005-07-08'
GROUP BY rental_day
ORDER BY rental_day

--Customers with overdue rentals - if suppose standard rental duration allowed is 7 days
SELECT * FROM (
SELECT c.customer_id, c.first_name, c.last_name, r.rental_date, r.return_date,
ROUND(EXTRACT(EPOCH FROM (r.return_date - r.rental_date)/86400),0) AS rental_duration
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.return_date IS NOT NULL
)
WHERE rental_duration > 7
ORDER BY rental_duration DESC

