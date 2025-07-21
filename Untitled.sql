
use project;

Select * from orders_data;
-- write a SQL query to list all distinct cities where orders have been shipped.
Select Distinct City from orders_data;

-- calculate the total selling price and profits for all orders

SELECT 
    `Order Id`,                  
    SUM(`Quantity` * `Unit_Selling_Price`) AS `Total Selling Price`,
    ROUND(SUM(`Total Profit`), 2) AS `Total Profit`
FROM `orders_data`
GROUP BY `Order Id`
ORDER BY `Total Profit` DESC ;

/* Find all orders from the 'Technology' category that were shipped using 'Second class'
shipmode, ordered by order date */

SELECT `Order Id`,  `Category`, `Ship Mode`
FROM `orders_data`
WHERE `Category` = 'Technology' AND `Ship Mode` = 'Second Class'  
ORDER BY `Order Date`;  

-- write a query to find the average order value by city
SELECT City,
    ROUND(AVG(Quantity * `Unit_Selling_Price`), 2) AS `AvgOrder`
FROM `orders_data`
Group by City;

-- find the top 5 city with the highest total quantity of products ordered

SELECT City, SUM(Quantity) AS `Total Quantity`
FROM `orders_data`
GROUP BY City
ORDER BY `Total Quantity` DESC
LIMIT 5;

-- use a window function to rank orders in each region by quantity in descending order

SELECT `Order Id`,`Region`,`Quantity`,
Dense_RANK() OVER (PARTITION BY `Region` ORDER BY `Quantity` DESC) AS `Quantity Rank`
FROM `orders_data`
ORDER BY `Region`,`Quantity Rank`;

/* list all orders placed in the first quarter of any year (jan to march), including
the total cost of the orders*/
 -- Select `Order Id`, `Order Date`, month(`Order Date`) as month from orders_data;
SELECT State,`Order Id`,`Order Date`,SUM(Quantity * `Unit_Selling_Price`) AS `Total_Value`
FROM `orders_data`
WHERE MONTH(`Order Date`) IN (1, 2, 3)  And State = 'Florida'
GROUP BY `Order Id`, `Order Date`  
ORDER BY Round(`Total_Value`,2) DESC;

-- Find the top 10 highest generating products

Select `Product Id` , Round(SUM(`Total Profit`),2) as `Profit`
From `orders_data`
Group By `Product Id`
Order By Profit Desc 
Limit 10;

-- using alternative cte window function
with cte as(
Select `Product Id` , Round(SUM(`Total Profit`),2) as `Profit`
, Row_Number() over (order by SUM(`Total Profit`) desc) as `hig`
From `orders_data`
Group By `Product Id`)

Select `Product Id`, `Profit`
from cte where `hig`<=10;

-- find top 3 higheset selling products in each region

with cte AS (
SELECT `Region`,`Product Id`,SUM(`Quantity`*`Unit_Selling_Price`) AS `Sales`,
ROW_NUMBER() OVER (PARTITION BY `Region` 
ORDER BY SUM(`Quantity`*`Unit_Selling_Price`) DESC) AS `SalesRank`
FROM `orders_data`
GROUP BY `Region`, `Product Id`
)
SELECT *
FROM cte
WHERE `SalesRank` <= 3
ORDER BY `Region`,`SalesRank`;

-- Find month over month growth comparison for each year
WITH MonthlySales AS (
    SELECT 
        YEAR(`Order Date`) AS `Year`,
        MONTH(`Order Date`) AS `Month`,
        DATE_FORMAT(`Order Date`, '%b') AS `MonthName`,  
        SUM(`Quantity` * `Unit_Selling_Price`) AS `Sales`
    FROM 
        `orders_data`
    WHERE
        YEAR(`Order Date`) IN (2022, 2023)
    GROUP BY 
        YEAR(`Order Date`), MONTH(`Order Date`), DATE_FORMAT(`Order Date`, '%b')
)
SELECT 
    `MonthName` AS `Month`,  -- Using the abbreviated month name
    ROUND(SUM(CASE WHEN `Year` = 2022 THEN `Sales` ELSE 0 END), 2) AS `Sales_2022`,
    ROUND(SUM(CASE WHEN `Year` = 2023 THEN `Sales` ELSE 0 END), 2) AS `Sales_2023`,
    ROUND(
        (SUM(CASE WHEN `Year` = 2023 THEN `Sales` ELSE 0 END) - 
        SUM(CASE WHEN `Year` = 2022 THEN `Sales` ELSE 0 END)
    ) / 
    NULLIF(SUM(CASE WHEN `Year` = 2022 THEN `Sales` ELSE 0 END), 0) * 100, 
    2) AS `YoY_Growth_Percent`
FROM 
    MonthlySales
GROUP BY 
    `MonthName`, `Month` 
ORDER BY 
    `Month`;  


-- for each category which month had highest sales

WITH cte AS (
    SELECT `Category`,
        DATE_FORMAT(`Order Date`, '%Y-%m') AS `order_year_month`,
        SUM(`Quantity` * `Unit_Selling_Price`) AS `sales`,
        ROW_NUMBER() OVER (PARTITION BY `Category` 
        ORDER BY SUM(`Quantity` * `Unit_Selling_Price`) DESC) AS `HigSal`
    FROM 
        `orders_data`
    GROUP BY 
        `Category`, 
        DATE_FORMAT(`Order Date`, '%Y-%m')
)
SELECT 
    `Category`,
    `order_year_month` AS `Order Year-Month`,
    Round(`sales` ,2)AS `Total Sales`
FROM cte
WHERE `HigSal` = 1
ORDER BY `Category`;



-- which sub category had highest growth by sales in 2023 compare to 2022

WITH cte AS (
    SELECT 
        `Sub Category` AS sub_category, 
        YEAR(`Order Date`) AS order_year,
        SUM(`Quantity` * `Unit_Selling_Price`) AS sales
    FROM 
        `orders_data`
    GROUP BY 
        `Sub Category`, YEAR(`Order Date`)
),
cte2 AS (
    SELECT 
        sub_category,
        ROUND(SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END), 2) AS sales_2022,
        ROUND(SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END), 2) AS sales_2023
    FROM 
        cte 
    GROUP BY 
        sub_category
)
SELECT 
    sub_category AS 'Sub Category', 
    sales_2022 AS 'Sales in 2022',
    sales_2023 AS 'Sales in 2023',
    Round(sales_2023 - sales_2022,2) AS 'Diff in Amount',
    ROUND(((sales_2023 - sales_2022) / NULLIF(sales_2022, 0)) * 100, 2) AS 'Growth Percentage'
FROM  
    cte2
ORDER BY 
    (sales_2023 - sales_2022) DESC
LIMIT 1;


