DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS city;

-- CREATING TABLE city
CREATE TABLE city
(
	city_id INT PRIMARY KEY,
    city_name VARCHAR(15),
    population BIGINT,
    estimated_rent FLOAT,
    city_rank INT
);

-- CREATING TABLE customer
CREATE TABLE customer
(
	customer_id INT PRIMARY KEY,
    customer_name VARCHAR(25),
    city_id INT,
    CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

-- CREATING TABLE products
CREATE TABLE products
(
	product_id INT PRIMARY KEY,
    product_name VARCHAR(35),
    price FLOAT
);

-- CREATING TABLE sales
CREATE TABLE sales
(
	sales_id INT PRIMARY KEY,
    sale_date DATE,
    product_id INT,
    customer_id INT,
    total FLOAT,
    rating INT,
    CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);
--------------------------------------------------------------------------------------------------------------------------------

-- QUESTIONS
-- 1. How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name, 
ROUND(population * 0.25/1000000,2) AS coffee_consumer_in_millions , 
city_rank
FROM city
ORDER BY 2 DESC;
-----------------------------------------------------------------------------------------------------------------------------------

-- 2. What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT city_name, SUM(total) as revenue 
FROM sales
JOIN customer
	ON sales.customer_id = customer.customer_id
JOIN city
	ON city.city_id = customer.city_id
WHERE EXTRACT(YEAR FROM sale_date) = 2023 
AND EXTRACT(QUARTER FROM sale_date) = 4
GROUP BY city_name
ORDER BY 2 DESC;
--------------------------------------------------------------------------------------------------------------------------

-- 3. How many units of each coffee product have been sold?

SELECT products.product_name, COUNT(sales.sales_id) AS total_orders
FROM products
LEFT JOIN sales
	ON sales.product_id = products.product_id
GROUP BY 1
ORDER BY 2 DESC;
------------------------------------------------------------------------------------------------------------------------------

-- 4. What is the average sales amount per customer in each city?

SELECT city_name, 
SUM(total) as revenue, 
COUNT(DISTINCT sales.customer_id) AS total_customers,
ROUND(SUM(total)/COUNT(DISTINCT sales.customer_id),2) AS avg_sales_per_customer
FROM sales
JOIN customer
	ON sales.customer_id = customer.customer_id
JOIN city
	ON city.city_id = customer.city_id
GROUP BY city_name
ORDER BY 2 DESC;
---------------------------------------------------------------------------------------------------------------------------

-- 5. Provide a list of cities along with their populations and estimated coffee consumers.

WITH cte_1 AS
(
SELECT 
city_name,
ROUND(population * 0.25 / 1000000,2) AS coffee_consumer_in_millions
FROM city
),
cte_2 AS
( 
SELECT city.city_name, 
COUNT(DISTINCT sales.customer_id) AS total_unique_customer_in_each_city
FROM sales
JOIN customer
	ON sales.customer_id = customer.customer_id
JOIN city
	ON customer.city_id = city.city_id
GROUP BY 1
)
SELECT 
cte_1.city_name,
cte_1.coffee_consumer_in_millions,
cte_2.total_unique_customer_in_each_city
FROM cte_1
JOIN cte_2
	ON cte_1.city_name = cte_2.city_name;
-----------------------------------------------------------------------------------------------------------------------------

-- 6. What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM 
(
SELECT 
city.city_name,
products.product_name,
COUNT(sales.sales_id) AS total_orders,
DENSE_RANK() OVER(PARTITION BY city.city_name ORDER BY COUNT(sales.sales_id) DESC) AS rank_no
FROM city
JOIN customer
	ON city.city_id = customer.city_id
JOIN sales
	ON customer.customer_id = sales.customer_id
JOIN products
	ON sales.product_id = products.product_id
GROUP BY 1, 2
) as t1
	WHERE rank_no <= 3;
------------------------------------------------------------------------------------------------------------------------------

-- 7. How many unique customers are there in each city who have purchased coffee products?

SELECT city.city_name,
COUNT(DISTINCT customer.customer_id) as unique_customers_in_each_city
FROM city
JOIN customer
	ON city.city_id = customer.city_id
JOIN sales
	ON customer.customer_id = sales.customer_id
WHERE sales.product_Id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1;
-----------------------------------------------------------------------------------------------------------------------------

-- 8. Find each city and their average sale per customer and avg rent per customer
WITH cte_1 
AS
(SELECT city_name, 
SUM(total) as revenue, 
COUNT(DISTINCT sales.customer_id) AS total_unique_customers,
ROUND(SUM(total)/COUNT(DISTINCT sales.customer_id),2) AS avg_sales_per_customer
FROM sales
JOIN customer
	ON sales.customer_id = customer.customer_id
JOIN city
	ON city.city_id = customer.city_id
GROUP BY city_name
ORDER BY 2 DESC
),
cte_2 AS
(
SELECT city_name, estimated_rent
FROM city
)
SELECT cte_1.city_name,
cte_1.total_unique_customers,
cte_1.avg_sales_per_customer,
cte_2.estimated_rent,
ROUND(cte_2.estimated_rent / total_unique_customers, 2) AS avg_rent_per_customer
FROM cte_1
JOIN cte_2
	ON cte_1.city_name = cte_2.city_name;
----------------------------------------------------------------------------------------------------------------------------------
    
-- 9. Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
WITH cte_1 as
(
SELECT 
city_name,
MONTH(sale_date) as month,
YEAR(sale_date) as year,
SUM(total) as total_sales
FROM sales
JOIN customer
	ON sales.customer_id = customer.customer_id
JOIN city
	ON city.city_id = customer.city_id
GROUP BY 1,2,3
ORDER BY 1,3,2
),
cte_2 as
(
SELECT city_name,
month,
year,
total_sales as current_month_sale,
LAG(total_sales, 1) OVER (PARTITION BY city_name) as last_month_sale
FROM cte_1
)
SELECT 
city_name,
month,
year,
current_month_sale,
last_month_sale,
ROUND((current_month_sale-last_month_sale)/last_month_sale * 100, 2) as growth_ratio
FROM cte_2
WHERE last_month_sale IS NOT NULL;
--------------------------------------------------------------------------------------------------------------------------------------------------

-- 10. Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer.

WITH cte_1 AS (
    SELECT 
        city_name, 
        SUM(total) AS revenue, 
        COUNT(DISTINCT sales.customer_id) AS total_unique_customers,
        ROUND(SUM(total) / COUNT(DISTINCT sales.customer_id), 2) AS avg_sales_per_customer,
        ROUND(MAX(population) * 0.25 / 1000000, 2) AS coffee_consumer_in_millions
    FROM sales
    JOIN customer
        ON sales.customer_id = customer.customer_id
    JOIN city
        ON city.city_id = customer.city_id
    GROUP BY city_name
),
cte_2 AS (
    SELECT 
        city_name, 
        estimated_rent
    FROM city
)
SELECT 
    cte_1.city_name,
    revenue,
    cte_1.total_unique_customers,
    coffee_consumer_in_millions,
    cte_1.avg_sales_per_customer,
    cte_2.estimated_rent,
    ROUND(cte_2.estimated_rent / cte_1.total_unique_customers, 2) AS avg_rent_per_customer
FROM cte_1
JOIN cte_2
    ON cte_1.city_name = cte_2.city_name
ORDER BY revenue DESC;

