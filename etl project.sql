CREATE TABLE df_orders (
	order_id INT PRIMARY KEY,
    order_date date,
    ship_mode varchar(20),
    segment varchar(20),
    country varchar(20),
    city varchar(20),
    state varchar(20),
    postal_code varchar(20),
    region varchar(20),
    category varchar(20),
    sub_category varchar(20),
    product_id varchar(20),
    quantity int,
    discount decimal(7,2),
    sale_price decimal(7,2),
    profit decimal(7,2)
);

SELECT * FROM df_orders;
DESC df_orders;

# top 10 highest revenue generating products
SELECT 
	product_id,
    SUM(quantity*sale_price) as total_revenue 
FROM df_orders
GROUP BY product_id
ORDER BY total_revenue DESC
LIMIT 5;

# top 5 highest selling products in each region
SELECT DISTINCT region FROM df_orders;
WITH temp AS (
SELECT
	product_id,
    region,
    SUM(quantity) as total_sold
FROM df_orders
GROUP BY product_id,region
)
SELECT * FROM (
SELECT 
	*,
	row_number() OVER(PARTITION BY region ORDER BY total_sold DESC) as row_num
FROM temp
) as A
WHERE row_num <= 5;

# find month over month revenue growth for 2022 and 2023 sales eg: Jan 2022 vs Jan 2023
SELECT DISTINCT year(order_date) FROM df_orders;
SELECT year(order_date) FROM df_orders;

WITH temp as(
SELECT YEAR(order_date) as year,MONTHNAME(order_date) as month_name,SUM(sale_price) as sales, MONTH(order_date) as month
FROM df_orders
GROUP BY month,year,month_name
ORDER BY month
)
SELECT month_name,
	SUM(CASE
		WHEN year = 2022 THEN sales ELSE 0 END) AS '2022',
	SUM(CASE
		WHEN year = 2023 THEN sales ELSE 0 END) AS '2023'
FROM temp
GROUP BY month_name;

# for each category, which month had highest sales
SELECT DISTINCT category FROM df_orders;

SELECT category, month(order_date) as order_month,year(order_date) as order_year,sum(sale_price) as sales
FROM df_orders
GROUP BY category,order_month,order_year
order by category;

WITH temp as(
SELECT date_format(order_date, '%Y/%m') AS yearmonth, 
       SUM(sale_price) AS sales, 
       category
FROM df_orders
GROUP BY category, yearmonth
)
SELECT * FROM(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY category ORDER BY sales) as row_num
FROM temp
) as A
WHERE row_num = 1;

# which sub category had the highest growth by profit in 2023 fromn 2022
WITH temp as(
SELECT sub_category, SUM(profit) pf, YEAR(order_date) as order_year
FROM df_orders
GROUP BY order_year, sub_category
ORDER BY sub_category, order_year
)
SELECT sub_category,
SUM(CASE WHEN order_year = 2022 THEN pf ELSE 0 END) as 2022_profit,
SUM(CASE WHEN order_year = 2023 THEN pf ELSE 0 END) as 2023_profit ,
(SUM(CASE WHEN order_year = 2023 THEN pf ELSE 0 END) - SUM(CASE WHEN order_year = 2022 THEN pf ELSE 0 END))/ SUM(CASE WHEN order_year = 2022 THEN pf ELSE 0 END) * 100 as growth_percent
FROM temp
GROUP BY sub_category
ORDER BY growth_percent DESC
LIMIT 1;

-- or with double CTE
WITH temp as(
SELECT sub_category, SUM(profit) pf, YEAR(order_date) as order_year
FROM df_orders
GROUP BY order_year, sub_category
ORDER BY sub_category, order_year
)
, temp2 as(
SELECT sub_category,
SUM(CASE WHEN order_year = 2022 THEN pf ELSE 0 END) as 2022_profit,
SUM(CASE WHEN order_year = 2023 THEN pf ELSE 0 END) as 2023_profit 
FROM temp
GROUP BY sub_category
)
SELECT sub_category,(2023_profit-2022_profit)/2022_profit*100 AS growth_percent
FROM temp2
GROUP BY sub_category
ORDER BY growth_percent DESC
LIMIT 1;
