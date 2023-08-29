show databases;
use superstore;
show TABLES;
select * from orders;
select * from categories;
drop table orders;

-- change data type order_date and ship_date (varchar to date) from table orders
update orders set order_date = str_to_date(order_date,'%m/%d/%Y');
update orders set ship_date = str_to_date(ship_date,'%m/%d/%Y');

-- drop column Column1
alter table categories
drop column Column1;

-- rename columns
alter table categories
rename column `Product ID` to product_id,
rename column Category to category,
rename column `Sub-Category` to sub_category,
rename column `Product Name` to product_name;


-- daily reporting
SELECT order_date, SUM(sales) AS total_sales FROM Orders GROUP BY 1;

-- monthly reporting
SELECT order_date, SUM(sales-discount) AS net_sales FROM Orders GROUP BY 1;

-- quarterly reporting
SELECT EXTRACT(QUARTER FROM order_date) AS order_quarter, SUM(sales) AS total_sales FROM Orders GROUP BY 1;

-- yearly reporting
SELECT EXTRACT(YEAR FROM order_date) AS order_year, SUM(sales) AS total_sales FROM Orders GROUP BY 1;


-- Actual VS Target
SELECT
	order_year,
	actual,
	(previous_actual + (previous_actual * 0.1)) AS target
FROM
	(
	SELECT
		YEAR(order_date) AS order_year,
		SUM(sales) AS actual,
		LAG(SUM(sales)) OVER (
		ORDER BY YEAR(order_date)) AS previous_actual
	FROM
		orders
	GROUP BY
		YEAR(order_date)) AS innerQuery;

-- current month vs last month
SELECT
	order_year,
	order_month,
	total_sales,
	previous_total_sales,
	((total_sales - previous_total_sales) / previous_total_sales) * 100 AS growth_percentage
FROM
	(
	SELECT
		YEAR(order_date) AS order_year,
		MONTH(order_date) AS order_month,
		SUM(sales) AS total_sales,
		LAG(SUM(sales)) OVER (
	ORDER BY
		YEAR(order_date),
		MONTH(order_date)) AS previous_total_sales
	FROM
		orders
	GROUP BY
		year(order_date),
		month(order_date)) AS innerQuery;

-- current quarter vs last quarter
SELECT
	order_year,
	order_quarter,
	total_sales,
	previous_total_sales,
	((total_sales - previous_total_sales) / previous_total_sales) * 100 AS growth_percentage
FROM
	(
	SELECT
		YEAR(order_date) AS order_year,
		QUARTER(order_date) AS order_quarter,
		SUM(sales) AS total_sales,
		LAG(SUM(sales)) OVER (
		ORDER BY YEAR(order_date),
		QUARTER(order_date)) AS previous_total_sales
	FROM
		orders
	GROUP BY
		YEAR(order_date),
		QUARTER(order_date)) AS innerQuery;

-- current year vs last year
SELECT
	order_year,
	total_sales,
	previous_total_sales,
	((total_sales - previous_total_sales) / previous_total_sales) * 100 AS growth_percentage
FROM
	(
	SELECT
		YEAR(order_date) AS order_year,
		SUM(sales) AS total_sales,
		LAG(SUM(sales)) OVER (
		ORDER BY YEAR(order_date)) AS previous_total_sales
	FROM
		orders
	GROUP BY
		YEAR(order_date)) AS innerQuery;


-- loss reporting
WITH cte AS
(
	SELECT
		o.order_date as order_date,
		o.state AS branch_store,
		c.product_name AS product_name,
		sum(o.profit) AS loss
	FROM
		orders AS o
	INNER JOIN categories AS c ON
		o.product_id = c.product_id
	WHERE
		o.profit < 0
	GROUP by
		o.order_id,
		o.product_id 
)

-- loss reporting monthly
SELECT
	DATE_FORMAT(order_date, '%Y-%m') as order_month,
	branch_store,
	product_name,
	loss
FROM cte

-- loss reporting quarterly
SELECT
	YEAR(order_date) as order_year,	
	QUARTER(order_date) as order_quarter,
	branch_store,
	product_name,
	loss
FROM cte

-- loss reporting yearly
SELECT 
	YEAR(order_date) as order_year,
	branch_store,
	product_name,
	loss
FROM cte	
	
-- segmentasi customer
SELECT
	customer_id,
	CASE
		WHEN total_sales < 200 THEN "BRONZE"
		WHEN total_sales > 500 THEN "GOLD"
		ELSE "SILVER"
	END AS customer_segmentation
FROM
	(
	SELECT
		customer_id,
		SUM(sales) AS total_sales
	FROM
		orders
	GROUP BY
		1) AS innerQuery;
	

-- segmentasi product
SELECT
	order_month,
	region,
	branch_store,
	product_name,
	total_order,
	CASE
		WHEN total_order < 5 THEN "3rd product"
		WHEN total_order > 10 THEN "1st product"
		ELSE "2nd product"
	END AS product_segmentation
FROM
	(
	select
		DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
		o.region AS region,
		o.state AS branch_store,
		c.product_name AS product_name,
		COUNT(o.order_id) AS total_order
	FROM
		orders AS o
	INNER JOIN categories AS c ON
		o.product_id = c.product_id
	GROUP BY
		o.product_id) AS innerQuery;

	
-- segmentasi toko cabang
SELECT
	state AS branch_store,
	order_year_month,
	total_sales,
	CASE
		WHEN total_sales < 1000 THEN "KATEGORI I"
		WHEN total_sales > 2000 THEN "KATEGORI III"
		ELSE "KATEGORI II"
	END AS branch_store_segmentation
FROM
	(
	SELECT
		state,
		SUM(sales) AS total_sales,
		DATE_FORMAT(order_date, '%Y-%m') AS order_year_month
	FROM
		orders
	GROUP BY
		state,
		MONTH(order_date)) AS innerQuery;
