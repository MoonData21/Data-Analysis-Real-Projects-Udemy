# Project 1: Overview of sale for 2004
# We need a breakdown by product, country, city, sales values, cost of sales, and net profit
select t1.orderDate, t1.orderNumber, priceEach, productName, productLine, buyPrice, city, country   
from orders t1
inner join orderdetails t2
on t1.ordernumber = t2.orderNumber
inner join products t3
on t2.productCode = t3.productCode
inner join customers t4
on t1.customerNumber = t4.customerNumber
where year(orderDate) = 2004;

# Project 2: A breakdown of products commonly purchased together, and any products that are rarely purchased together 

with prod_sales as
(
select orderNumber, t1.productCode, productLine 
from orderdetails t1
inner join products t2
on t1.productCode = t2.productCode
)

select distinct t1.orderNumber, t1.productLine as product_one, t2.productLine as product_two 
from prod_sales t1
left join prod_sales t2
on t1.orderNumber = t2.orderNumber and t1.productLine <> t2.productLine;

# Project 3: A breakdown of sales, but also show their credit limit
WITH sales AS (
    SELECT 
        t1.orderNumber, 
        t1.customerNumber, 
        t3.creditLimit,
        t2.quantityOrdered, 
        t2.priceEach, 
        t2.priceEach * t2.quantityOrdered AS sales_value
    FROM orders t1
    INNER JOIN orderdetails t2 ON t1.orderNumber = t2.orderNumber
    INNER JOIN customers t3 ON t1.customerNumber = t3.customerNumber
)

SELECT 
    orderNumber, 
    customerNumber, 
    creditLimit,
    CASE 
        WHEN creditLimit < 75000 THEN 'a: Less than $75K'
        WHEN creditLimit BETWEEN 75000 AND 100000 THEN 'b: $75K - $100K'
        WHEN creditLimit BETWEEN 100000 AND 150000 THEN 'c: $100K - $150K'
        WHEN creditLimit > 150000 THEN 'd: Over $150K'
        ELSE 'Other'
    END AS creditlimit_group,
    SUM(sales_value) AS total_sales_value
FROM sales
GROUP BY orderNumber, customerNumber, creditLimit, creditlimit_group;

# Project 4 - Will New Customers Spend More or Not Question
with main_cte as 
(
select orderNumber, orderDate, customerNumber, sum(sales_value) as sales_value
from
(select t1.orderNumber, orderDate, customerNumber, productCode, quantityOrdered * priceEach as sales_value
from orders t1
inner join orderdetails t2
on t1.orderNumber = t2.orderNumber) main
group by orderNumber, orderDate, customerNumber
),

sales_query as
( 
select t1.*, customerName, row_number() over (partition by customerName order by orderdate) as purchase_number, 
lag(sales_value) over (partition by customerName order by orderdate) as prev_sales_values
from main_cte t1
inner join customers t2
on t1.customerNumber = t2.customerNumber)

select *, sales_value - prev.sales_value as purchase_value_charge 
from sales_query 
where prev_sales_value is not null;

# Project 5 show me a view of where the customers of each office are located?

WITH main_cte AS (
    SELECT 
        t1.orderNumber, 
        t2.quantityOrdered, 
        t2.productCode, 
        t2.quantityOrdered * t2.priceEach AS sales_value,
        t3.city AS customer_city, 
        t3.country AS customer_country, 
        t4.productLine, 
        t6.city AS office_city, 
        t6.country AS office_country
    FROM orders t1
    INNER JOIN orderdetails t2 ON t1.orderNumber = t2.orderNumber
    INNER JOIN customers t3 ON t1.customerNumber = t3.customerNumber
    INNER JOIN products t4 ON t2.productCode = t4.productCode
    INNER JOIN employees t5 ON t3.salesRepEmployeeNumber = t5.employeeNumber
    INNER JOIN offices t6 ON t5.officeCode = t6.officeCode
)

SELECT 
    orderNumber, 
    customer_city, 
    customer_country, 
    productLine, 
    office_city, 
    office_country, 
    SUM(sales_value) AS total_sales_value  
FROM main_cte
GROUP BY 
    orderNumber, 
    customer_city, 
    customer_country, 
    productLine, 
    office_city, 
    office_country;
    
# Project 6: Customers Affected By Late Shipping:
select *, date_add(shippedDate, interval 3 day) as latest_arrival,
case when date_add(shippedDate, interval 3 day) > requiredDate then 1
else 0 end as late_flag
from orders
where
(case when date_add(shippedDate, interval 3 day) > requiredDate then 1 else 0 end ) = 1;

# Project 7 (Advanced): Customers with breakdown of sales and money still owed to the company (customers have gone over credit limit)
with cte_sales as
(
select orderDate, t1.customerNumber, t1.orderNumber, customerName, productCode, creditLimit, quantityOrdered * priceEach as sales_value
from orders t1
inner join orderdetails t2
on t1.orderNumber = t2.orderNumber
inner join customers t3
on t1.customerNumber = t3.customerNumber
),

running_totals_sales_cte as 
(
select *, lead(orderDate) over (partition by customerNumber order by orderDate) as next_order_date
from
(
select orderDate, orderNumber, customerNumber, customerName, creditLimit,
sum(sales_value) as sales_value
from cte_sales
group by orderDate, orderNumber, customerNumber, customerName, creditLimit
) subquery )
,
payments_cte as 
(
select *
from payments),

main_cte as 
(
select t1.*,
sum(sales_value) over (partition by t1.customerNumber order by orderDate) as running_total_sales,
sum(amount) over (partition by t1.customerNumber order by orderDate) as running_total_payments
from running_totals_sales_cte t1
left join payments_cte t2
on t1.customerNumber = t2.customerNumber 
and t2.paymentDate between t1.orderDate 
and case when t1.next_order_date is null
then current_date 
else next_order_date end
order by t1.customerNumber, orderDate
)
select *, running_total_sales - running_total_payments as money_owed,
creditLimit - (running_total_sales - running_total_payments) as difference
from main_cte;

# Project 7: Customers Continued, to get the creditlimit overage amount 
select *, sum(amount) over (partition by customerNumber order by paymentDate) as running_total_payments
from payments