-- Who is the senior most employee based on job title?

SELECT *
FROM
	employee
ORDER BY
	levels DESC
LIMIT 1

-- Which countries have the most Invoices?

SELECT 
	billing_country,
	COUNT(*) as invoice_count
FROM
	invoice
GROUP BY
	billing_country
ORDER BY
	invoice_count DESC
	
-- What are the top 3 values of total invoice?

SELECT 
	total
FROM
	invoice
ORDER BY
	total DESC
LIMIT 3

-- Which city has the best customers? Write a query that returns one city that has the highest sum of invoice totals.
-- Return both the city name & sum of all invoice totals

SELECT 
	billing_city,
	SUM(total) as invoice_total
FROM
	invoice
GROUP BY
	billing_city
ORDER BY
	invoice_total DESC
LIMIT 1

-- Who is the best customer? The customer who has spent the most money will be declared the best customer.
-- Write a query that returns the person who has spent the most money.

SELECT
	c.customer_id,
	c.first_name,
	c.last_name,
	SUM(i.total) as invoice_total
FROM
	customer c
JOIN 
	invoice i
ON 
	c.customer_id = i.customer_id
GROUP BY
	c.customer_id
ORDER BY
	invoice_total DESC
LIMIT 1
	
-- Write a query to return the email, first name, last name & genre of all Rock music listeners.
-- Return your list ordered alphabetically by email starting with A

SELECT
	DISTINCT email,
	first_name,
	last_name
FROM
	customer
JOIN
	invoice ON customer.customer_id = invoice.customer_id
JOIN
	invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE
	track_id IN (
  SELECT track_id FROM track
  JOIN genre ON track.genre_id = genre.genre_id
  WHERE genre.name LIKE 'Rock'
	)
ORDER BY
	email;
	
-- Let's invite the artists who have written the most rock music in our dataset.
-- Write a query that returns the Artist name and total track count of the top 10 rock bands.

SELECT
	artist.artist_id,
	artist.name,
	COUNT(artist.artist_id) as number_of_songs
FROM
	track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE
	genre.name LIKE 'Rock'
GROUP BY
	artist.artist_id
ORDER BY
	number_of_songs DESC
LIMIT 10;
	
-- Return all the track names that have a song length longer than the average song length.
-- Return the Name and Milliseconds for each track.
-- Order by the song length with the longest songs listed first.
	
SELECT
	name,
	milliseconds
FROM 
	track
WHERE
	milliseconds > (
   SELECT AVG(milliseconds) as avg_track_length
   FROM track
	)
ORDER BY
	milliseconds DESC
	
-- Find how much amount spent by each customer on artists?
-- Write a query to return customer name, artist name & total spent.

WITH best_selling_artist AS (
		SELECT artist.artist_id AS artist_id, artist.name as artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
		FROM invoice_line
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN album ON album.album_id = track.album_id
		JOIN artist ON artist.artist_id = album.artist_id
		GROUP BY 1
		ORDER BY 3 DESC
		LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name AS artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- We want to find out the most popular music Genre for each country.
-- We determine the most popular genre as the genre with the highest amount of purchases.
-- Write a query that returns each country along with the top Genre.
-- For countries where the maximum number of purchases is shared return all Genres.

WITH popular_genre AS (
	SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id,
		ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC)
		AS RowNO
	FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		join genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNO <= 1

SELECT 
	al.album_id,
	al.title,
	al.artist_id,
	name
FROM
	album al
JOIN
	artist ar
ON
	al.artist_id = ar.artist_id

-- Write a query that determines the customer that has spent the most on music for each country.
-- Write a query that returns the country along with the top customer and how much they spent.
-- For countries where the top amount spent is shared, provide all customers who spent this amount.

WITH customer_with_country AS (
				SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending,
				ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
				FROM invoice
				JOIN customer ON customer.customer_id = invoice.customer_id
				GROUP BY 1,2,3,4
				ORDER BY 4 ASC, 5 DESC
)
SELECT * FROM customer_with_country WHERE RowNo <= 1


WITH RECURSIVE
	customer_with_country AS (
		SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),
		
	country_max_spending AS (
		SELECT billing_country, MAX(total_spending) AS max_spending
		FROM customer_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customer_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;

-- What is the monthly invoice quantity?

WITH joined_music_store AS
(SELECT 
  cu.customer_id, cu.first_name, cu.last_name, cu.company, cu.city, cu.state, cu.country,
  inv.invoice_date, inv.billing_city, inv.billing_state, inv.billing_country, inv.total,
  ivl.track_id, ivl.unit_price, ivl.quantity,
  tr.track_id, tr.name, tr.composer, tr.milliseconds, tr.bytes, tr.unit_price,
  al.title, ar.name as artist_name
FROM `music_store.customer` cu
JOIN `music_store.invoice` inv ON cu.customer_id = inv.customer_id
JOIN `music_store.invoice_line` ivl ON inv.invoice_id = ivl.invoice_id
JOIN `music_store.track` tr ON tr.track_id = ivl.track_id
JOIN `music_store.album` al ON tr.album_id = al.album_id
JOIN `music_store.artist` ar ON al.artist_id = ar.artist_id)
SELECT 
  EXTRACT(MONTH FROM invoice_date) as extracted_month,
  SUM(quantity) AS monthly_quantity
FROM
  joined_music_store
GROUP BY
  extracted_month
ORDER BY monthly_quantity DESC 

-- What is the average age for employees by job title?

WITH employee_with_age_table AS
(SELECT 
  employee_id, CONCAT(first_name, " ", last_name) AS full_name, 
  DATE_DIFF(DATE(hire_date), DATE(birthdate), year) AS employee_age,
  title, birthdate,
  hire_date, state, country,
  
FROM
  `music_store.employee`)
SELECT
  title, 
  ROUND(AVG(employee_with_age_table.employee_age),2) AS average_employee_age
FROM
  employee_with_age_table
GROUP BY
  title
ORDER BY average_employee_age DESC









