-- create database 
CREATE DATABASE e_commerce_db;

-- create table 'sales'
CREATE TABLE sales (
order_date DATE,
time TIME,
difference FLOAT,
customer_id INT ,
gender VARCHAR(20),
device_type VARCHAR(10),
customer_login_type VARCHAR(20),
product_category VARCHAR(50),
product VARCHAR(50),
sales INT,
quantity INT,
discount FLOAT,
profit FLOAT,
shipping_cost FLOAT,
order_priority VARCHAR(10),
payment_method VARCHAR(20)
);

-- Then Import the csv file through Table Data Import Wizard

-- Data Exploration and Cleaning 

SELECT COUNT(*) FROM sales;

SELECT COUNT(DISTINCT customer_id) AS unique_cus_count 
FROM sales;

SELECT DISTINCT product_category FROM sales;

SELECT * FROM sales
WHERE sales IS NULL OR quantity IS NULL OR discount IS NULL OR shipping_cost IS NULL OR order_priority IS NULL;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM sales
WHERE sales IS NULL OR quantity IS NULL OR discount IS NULL OR shipping_cost IS NULL OR order_priority IS NULL;

SELECT COUNT(*) FROM sales;


-- Data Analysis and Findings 

-- Basic Level Queries 

-- Task 1: write a query to find total revenue generated
SELECT SUM(sales) AS total_revenue
FROM sales;

-- Task 2: write a query to find which month had the highest total sales
SELECT DATE_FORMAT(order_date, '%M') as month, SUM(sales) as total_revenue
FROM sales
GROUP BY month
ORDER BY total_revenue DESC
LIMIT 1;

-- Task 3: write a query to find what are the top 10 selling products by quantity
SELECT product, SUM(quantity) as total_quantity_sold
FROM sales 
GROUP BY product
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- Task 4: write a query to find which product category generates the most revenue
SELECT product_category, SUM(sales) AS total_revenue 
FROM sales 
GROUP BY product_category
ORDER BY total_revenue DESC;

-- Task 5: write a query to find top 5 products generate the highest revenue 
SELECT product, SUM(sales) AS total_revenue 
FROM sales
GROUP BY product 
ORDER BY total_revenue DESC
LIMIT 5; 

-- Task 6: write a query to find mobile users contribute more to sales than web users?
SELECT device_type, SUM(sales) as total_revenue 
FROM sales
GROUP BY device_type
ORDER BY total_revenue DESC;

-- Task 7: write a query to find how do purchasing behaviors differ between genders?
SELECT gender, COUNT(quantity) AS total_order_placed
FROM sales 
GROUP BY gender
ORDER BY total_order_placed DESC;

-- Task 8: write a query to find how do 'Members' and 'Guests' differ in purchasing patterns
SELECT customer_login_type, COUNT(*) as total_order_placed
FROM sales 
GROUP BY customer_login_type
ORDER BY total_order_placed DESC;

-- Task 9: write a query to find which which customers have the highest total spend
SELECT customer_id, SUM(sales) as total_spend
FROM sales 
GROUP BY customer_id
ORDER BY total_spend DESC;

-- Task 10: write a query to find which payment method used the most for placing order 
SELECT payment_method, count(*) as total_order_placed
FROM sales 
GROUP BY payment_method
ORDER BY total_order_placed DESC;


-- Intermediate Level Queries

-- Task 1: write a query to find what is the mean delivery duration across all orders
SELECT ROUND(AVG(difference),2) as avg_delivery_time
FROM sales;

-- Task 2: write a query to find what categories do customer type prefer

SELECT 
  Customer_Login_Type,
  Product_Category,
  COUNT(*) AS Orders
FROM 
  sales
GROUP BY 
  Customer_Login_Type, Product_Category
ORDER BY 
  Customer_Login_Type, Orders DESC;

-- Task 3: write a query to find what is the repeat customer rate

SELECT ROUND((COUNT(*) * 100) / 
(SELECT COUNT(DISTINCT customer_id) FROM sales) ,2) AS repeated_customer_rate
FROM (
      SELECT customer_id
      FROM sales 
      GROUP BY customer_id 
      HAVING COUNT(*) >1 
) AS repeated_cus_list;

-- Task 4: write a query to find what is the average time between customer type purchases

WITH ranked_orders AS (
  SELECT 
    customer_id,
    order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS PreviousPurchase
  FROM sales
)
SELECT 
  AVG(DATEDIFF(order_date, PreviousPurchase)) AS Avg_Days_Between_Purchases
FROM ranked_orders
WHERE PreviousPurchase IS NOT NULL;

-- Task 5: write a query to find which products lead in sales within each category

WITH top_selling_product as (
SELECT product_category, product, SUM(sales) as total_revenue ,
DENSE_RANK() OVER(PARTITION BY product_category ORDER BY SUM(sales) DESC) as rnk
FROM sales 
GROUP BY product_category,product
)
  SELECT product_category,product, total_revenue
  FROM top_selling_product
  WHERE rnk<=1;

-- Task 6: How do sales from mobile and web platforms evolve monthly?
SELECT MONTH(order_date) as month, device_type, SUM(sales) as total_revenue
FROM sales 
GROUP BY month, device_type
ORDER BY month;


-- Advance Level Queries 

-- Task 1: write a query to find Customer Lifetime Value (CLV) Estimation

WITH customer_orders AS (
    SELECT 
        Customer_id,
        COUNT(*) AS Total_Orders,
        SUM(Sales) AS Total_Revenue,
        AVG(Sales) AS Avg_Order_Value
    FROM sales
    GROUP BY Customer_id
),
customer_life AS (
    SELECT 
        Customer_id,
        DATEDIFF(MAX(Order_Date), MIN(Order_Date)) /30  AS Active_months
    FROM sales
    GROUP BY Customer_id
)
SELECT 
    o.Customer_id,
    ROUND(o.Avg_Order_Value * o.Total_Orders / l.Active_months, 2) AS CLV,
    o.Total_Revenue,
    o.Total_Orders,
    l.Active_months
FROM 
    customer_orders o
JOIN 
    customer_life l ON o.Customer_id = l.Customer_id
ORDER BY CLV DESC
LIMIT 10;

-- Task 2: write a query to find which products are commonly purchased together

SELECT 
    a.Product AS Product_1,
    b.Product AS Product_2,
    COUNT(*) AS Times_Bought_Together
FROM 
    sales a
JOIN 
    sales b 
    ON a.customer_id = b.customer_id 
    AND a.Product < b.Product
GROUP BY 
    a.Product, b.Product
ORDER BY 
    Times_Bought_Together DESC
LIMIT 10;

-- Task 3: write a query to find 3 months moving average

SELECT
    Month,
    Monthly_Sales,
    ROUND(AVG(Monthly_Sales) OVER (
        ORDER BY Month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS Moving_Avg_3M
FROM (
    -- Subquery with monthly sales
    SELECT 
        DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
        SUM(Sales) AS Monthly_Sales
    FROM 
        sales
    GROUP BY 
        DATE_FORMAT(Order_Date, '%Y-%m')
) AS sales_by_month;

-- Task 4: write a query to find month over month sales growth percentage

WITH previous_month_revenues as (
SELECT DATE_FORMAT(order_date, '%Y-%m-%d') as date, SUM(sales) as total_revenue ,
LAG(SUM(sales)) OVER(ORDER BY DATE_FORMAT(order_date, '%Y-%m-%d')) as previous_month_revenue
FROM sales 
GROUP BY date
)
  SELECT date, total_revenue, previous_month_revenue,
  (total_revenue - previous_month_revenue) as difference,
  ROUND(((total_revenue - previous_month_revenue) / previous_month_revenue) *100, 2) as sales_grwoth_percentage
  FROM previous_month_revenues
  ORDER BY date;