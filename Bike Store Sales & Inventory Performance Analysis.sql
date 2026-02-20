-- Sales Analysis

-- Total Revenue

select 
	ROUND(SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)),
            2) AS Total_Revenue
from 
	order_items;
    
-- Total Orders

select 
	count(distinct orders.order_id) as Total_orders
from orders;

-- Total Unit Sold

select 
	SUM(order_items.quantity) AS Total_Unit_Sold
from order_items;

-- Total Customers

select 
	count(distinct customers.customer_id) as Total_Customers
from customers;

-- Repeat / Loyal Customers

SELECT 
    COUNT(*) AS Repeat_Customers
FROM (
    SELECT 
        customer_id
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
) AS repeat_data;

-- A)top performing product 

SELECT 
    products.product_name,
    SUM(order_items.quantity) AS Total_Quantity_Sold,
    ROUND(SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)),
            2) AS Total_Revenue
FROM
    products
        JOIN
    order_items ON order_items.product_id = products.product_id
GROUP BY products.product_name
ORDER BY Total_Revenue DESC
LIMIT 10;

-- B)  What is the total sales amount (considering discounts) for each product in a given year?   
SELECT 
    p.product_id,
    p.product_name,
    YEAR(o.order_date) AS year,
    ROUND(SUM(oi.list_price * oi.quantity * (1 - oi.discount)),
            2) AS total_sales_amount
FROM
    Order_items oi
        JOIN
    Products p ON oi.product_id = p.product_id
        JOIN
    Orders o ON oi.order_id = o.order_id
GROUP BY year , p.product_id , p.product_name
ORDER BY year , total_sales_amount DESC;

-- What is the total sales amount (considering discounts) for each category in a given year?  

SELECT 
    c.category_name,
    YEAR(o.order_date) AS year,
    ROUND(SUM(oi.list_price * oi.quantity * (1 - oi.discount)), 2) AS total_sales_amount
FROM
    Order_items oi
        JOIN
    Products p ON oi.product_id = p.product_id
        JOIN
    Categories c ON p.category_id = c.category_id  
        JOIN
    Orders o ON oi.order_id = o.order_id
GROUP BY year, c.category_name                      
ORDER BY year, total_sales_amount DESC;


--  C) Seasonal Sales Trends (Monthly & Quarterly)

SELECT 
    YEAR(orders.order_date) AS Sales_Year,
    QUARTER(orders.order_date) AS Sales_Quarter,
    MONTH(orders.order_date) AS Sales_Month,
    SUM(order_items.quantity) AS Units_sold,
    ROUND(SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)),
            2) AS Monthly_Revenue
FROM
    orders
        JOIN
    order_items ON order_items.order_id = orders.order_id
GROUP BY Sales_Year , Sales_Quarter , Sales_Month
ORDER BY Sales_Year , Sales_Month;

-- Product Line Insights (Brand & Category Performance)    

SELECT 
    brands.brand_name,
    categories.category_name,
    SUM(order_items.quantity) AS Total_Units,
    ROUND(SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)),
            2) AS Brand_Category_Revenue,
    AVG(order_items.discount) AS Avg_Discount_offered
FROM
    products
        JOIN
    brands ON brands.brand_id = products.brand_id
        JOIN
    categories ON categories.category_id = products.product_id
        JOIN
    order_items ON order_items.product_id = products.product_id
GROUP BY brands.brand_name , categories.category_name
ORDER BY Brand_Category_Revenue;

-- 2) Customer Buying Behavior & Segmentation
-- A) Avg Order Value per store

SELECT 
    store_name, ROUND(AVG(order_Total), 2) AS Avg_Order_Value
FROM
    (SELECT 
        stores.store_name,
            SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)) AS order_Total
    FROM
        stores
    JOIN orders ON orders.store_id = stores.store_id
    JOIN order_items ON order_items.order_id = orders.order_id
    GROUP BY stores.store_name , orders.order_id) AS Order_Summaries
GROUP BY store_name;

-- B) VIP Customers

SELECT 
    customers.customer_id,
    customers.first_name,
    customers.last_name,
    COUNT(orders.order_id) AS Total_Orders,
    SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)) AS Totala_spent
FROM
    customers
        JOIN
    orders ON customers.customer_id = orders.customer_id
        JOIN
    order_items ON orders.order_id = order_items.order_id
GROUP BY customers.customer_id , customers.first_name , customers.last_name
HAVING COUNT(orders.order_id) > 5
    OR SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)) > 10000
ORDER BY 5 DESC;

-- 3) Inventory Optimization & Stock Management
-- A) Identify products that frequently run low in inventory across stores.

SELECT 
    stores.store_name,
    products.product_name,
    stocks.quantity AS Current_stock
FROM
    stocks
        JOIN
    products ON stocks.product_id = products.product_id
        JOIN
    stores ON stocks.store_id = stores.store_id
WHERE
    stocks.quantity < 10
ORDER BY stocks.quantity ASC , stores.store_name;

-- B) Find stores with excess inventory for specific models.

SELECT 
    stores.store_name,
    products.model_year,
    products.product_name,
    stocks.quantity AS Current_stock
FROM
    stocks
        JOIN
    products ON stocks.product_id = products.product_id
        JOIN
    stores ON stocks.store_id = stores.store_id
WHERE
    stocks.quantity >= 25
ORDER BY stocks.quantity ASC , stores.store_name;

-- 4) Store & Staff Performance Evaluation  
-- A) Compare sales performance across store locations.

SELECT 
    store_name, ROUND(SUM(order_Total), 2) AS Total_Order_Value
FROM
    (SELECT 
        stores.store_name,
            SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)) AS order_Total
    FROM
        stores
    JOIN orders ON orders.store_id = stores.store_id
    JOIN order_items ON order_items.order_id = orders.order_id
    GROUP BY stores.store_name , orders.order_id) AS Order_Summaries
GROUP BY store_name;

-- B) dentify highest and lowest performing sales staff.

SELECT 
    CONCAT(staffs.first_name, ' ', staffs.last_name) AS Full_Name,
    ROUND(SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)),
            2) AS Sales_By_Staff
FROM
    staffs
        LEFT JOIN
    orders ON orders.staff_id = staffs.staff_id
        LEFT JOIN
    order_items ON order_items.order_id = orders.order_id
GROUP BY CONCAT(staffs.first_name, ' ', staffs.last_name)
ORDER BY 2 DESC;

-- Analyze repeat purchase rates per customer

with customers_orders as (
	select 
		customer_id,
        count(order_id) as Total_orders
	from orders
    group by customer_id
)

select
	count(case when Total_orders > 1 then 1 end ) as repeat_customers,
    count(*) as total_customers,
    round(
    COUNT(CASE WHEN Total_orders > 1 THEN 1 END) * 100.0 
        / COUNT(*), 
        2
    ) AS repeat_purchase_rate_percentage
FROM  customers_orders;
 
-- Determine if certain product categories or brands influence loyalty.

-- Step 1: Calculate total orders per customer
WITH customer_loyalty AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
),

-- Step 2: Map customers to product categories they purchased
customer_categories AS (
    SELECT DISTINCT
        o.customer_id,
        c.category_name
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
)

-- Step 3: Calculate loyalty rate per category
SELECT 
    cc.category_name,
    COUNT(DISTINCT cc.customer_id) AS total_customers,
    COUNT(DISTINCT CASE 
        WHEN cl.total_orders > 1 THEN cc.customer_id 
    END) AS loyal_customers,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN cl.total_orders > 1 THEN cc.customer_id 
        END) * 100.0
        / COUNT(DISTINCT cc.customer_id),
        2
    ) AS loyalty_rate_percentage
FROM customer_categories cc
JOIN customer_loyalty cl 
    ON cc.customer_id = cl.customer_id
GROUP BY cc.category_name
ORDER BY loyalty_rate_percentage DESC;

