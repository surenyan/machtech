CREATE TABLE raw_orders (
    order_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    product_name VARCHAR(50),
    price DECIMAL(10,2),
    quantity INT,
    order_date DATE,
    status_id INT
);





CREATE OR REPLACE VIEW error_log AS
SELECT order_id, 'price' AS column_name, 'Negative Price' AS error_type, price::TEXT AS invalid_value 
FROM raw_orders WHERE price < 0
UNION ALL
SELECT order_id, 'email' AS column_name, 'Missing @ symbol' AS error_type, email AS invalid_value 
FROM raw_orders WHERE email NOT LIKE '%@%'
UNION ALL
SELECT order_id, 'quantity' AS column_name, 'Zero or Negative' AS error_type, quantity::TEXT AS invalid_value 
FROM raw_orders WHERE quantity <= 0 OR quantity IS NULL
UNION ALL
SELECT order_id, 'order_date' AS column_name, 'Future Date' AS error_type, order_date::TEXT AS invalid_value 
FROM raw_orders WHERE order_date > CURRENT_DATE;


 SELECT * FROM error_log;




 CREATE OR REPLACE VIEW cleaned_orders AS
SELECT 
    order_id,
    customer_name,
    email,
    product_name,
    price,
    quantity,
    (price * quantity) AS total_amount, 
    order_date,
    CASE 
        WHEN status_id = 1 THEN 'Pending'
        WHEN status_id = 2 THEN 'Shipped'
        WHEN status_id = 3 THEN 'Delivered'
        ELSE 'Unknown'
    END AS order_status
FROM raw_orders
WHERE 
    price >= 0 
    AND email LIKE '%@%' 
    AND quantity > 0 
    AND order_date <= CURRENT_DATE;


 SELECT * FROM cleaned_orders;




-- Agg1 - total revenue and items sold by product
SELECT 
    product_name, 
    SUM(quantity) AS total_units_sold, 
    SUM(total_amount) AS total_revenue
FROM cleaned_orders
WHERE order_status = 'Delivered'
GROUP BY product_name
ORDER BY total_revenue DESC;

-- Agg2- Orders by status
SELECT 
    order_status, 
    COUNT(order_id) AS order_count
FROM cleaned_orders
GROUP BY order_status;


-- Agg3- monthly ales
SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS sales_month,
    COUNT(order_id) AS total_orders,
    SUM(total_amount) AS monthly_revenue
FROM cleaned_orders
WHERE order_status = 'Delivered'
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY sales_month;



-- Agg4- top5 customers by revenue
SELECT 
    customer_name,
    COUNT(order_id) AS number_of_orders,
    SUM(total_amount) AS total_spent
FROM cleaned_orders
WHERE order_status = 'Delivered'
GROUP BY customer_name
ORDER BY total_spent DESC
LIMIT 5;




-- Agg5- average order value
SELECT 
    ROUND(AVG(total_amount), 2) AS average_order_value
FROM cleaned_orders
WHERE order_status = 'Delivered';
	