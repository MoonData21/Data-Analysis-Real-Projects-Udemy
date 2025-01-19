/*
create schema `learning`;

create table CUSTOMERS(CustomerID int, CustomerFirstName char, CustomerLastName char);

drop table customers;

select * from learning.customers;

Insert into learning.customers
Values
(102, 'Bob', 'Doe'),
(103, 'Harry', 'Burns');

drop schema learning;
*/
select * from classicmodels.customers
limit 10;

select * from customers
where contactlastname <> 'Young';
/* Not equal is <> or != */

select * from customers
where country = 'USA' and contactFirstName = 'Julie';

select contactFirstName, contactLastName, city, country from customers
where country = 'Norway' 
or country = 'Sweden';

/* When there is multiple or conditions like USA and UK, you have to use the parantheses*/
select * from customers
where (country = 'USA' or country = 'UK')
and contactLastName = 'Brown';

select email from employees
where jobTitle = 'Sales Rep';

select * from employees
where lower(firstName)='leslie';
/* MySQL workbench is not case sensitive, but PostGressSQL and MYSQLServer are case sensitive.*/

select *, upper(firstName) as UpperCaseName from employees
limit 10; 

/* Joins Examples */

select t1.customerName, t2.amount, t2.paymentDate from customers t1
join payments t2
on t1.customerNumber = t2.customerNumber;

select t1.customerName, t2.amount, t2.paymentDate from customers t1
left join payments t2
on t1.customerNumber = t2.customerNumber
where t2.customerNumber is null;

select t2.contactFirstName, t2.contactLastName, t1.orderDate, t1.status from orders t1
join customers t2
on t1.customerNumber = t2.customerNumber;

select t1.contactFirstName, t1.contactLastName, t2.orderDate, t2.orderNumber  from customers t1
left join orders t2
on t1.customerNumber = t2.customerNumber
where t2.orderNumber is null;

select paymentDate, round(sum(amount), 1) as total_payments
from payments
group by paymentDate
order by paymentDate;

/* Having is the same as WHERE, but is used after the group by clause with aggregate functions. */
SELECT paymentDate, sum(amount) as total_payments
from payments
group by paymentDate
having total_payments > 50000
order by total_payments desc;

select count(distinct orderNumber) as Distinct_orderNumber
from orderdetails;

/*Max and Min example*/
select paymentDate,
max(amount) as highest_payment,
min(amount) as lowest_payment
from payments
group by paymentDate
having paymentDate = '2003-12-09';

/* Average Example*/
select paymentDate, avg(amount) as average_payment_received
from payments
group by paymentDate
order by paymentDate;

select avg(amount) as average
from payments;

/* inner join example*/
select * from orders t1
inner join customers t2
on t1.customerNumber = t2.customerNumber; 

/* Subquery Example */
select avg(orders) 
from 
(select orderDate, count(orderNumber) orders
from orders
group by orderDate) t1
where orderDate > '2005-05-01';

/* CTE expression example */
with cte_orders as

(select orderdate, count(ordernumber) orders
from orders
group by orderdate),

cte_payments as
(select * from payments)

select avg(orders)
from cte_orders

where orderdate > '2005-05-01'

/* Case Statement - Returns a specified value based on a condition,
and is often used to group a column into ranges, or to create a flag. */


