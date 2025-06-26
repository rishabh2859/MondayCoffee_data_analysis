create table city(
city_id int,
city_name varchar(20),
population bigint,
estimated_rent bigint,
city_rank int
)
create table customers(
customer_id	int,
customer_name varchar(20),	
city_id int
);
create table products(
 product_id	int,
 product_name varchar(20),
 price int
)
alter table products alter product_name type text;
create table sales(
sale_id	int,
sale_date	date,
product_id	int,
customer_id	int,
total	int,
rating int
);
--Coffee Consumers Count
--How many people in each city are estimated to consume coffee, 
--given that 25% of the population does?
select city_id,city_name,(0.25)*population as coffee_consumers from city;
--Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the 
--last quarter of 2023?
with cte as(select sale_id,sale_date,s.product_id,s.customer_id,total,price,c.city_id,ci.city_name,(total*price) as revenue from sales as s
join products as p
on s.product_id=p.product_id
join customers as c
on s.customer_id=c.customer_id
join city as ci
on c.city_id=ci.city_id
where sale_date>=DATE'2023-12-31'-interval '90 days' and extract(year from sale_date)=2023)
select city_name,sum(revenue) as total_revenue from cte
group by 1;
--Sales Count for Each Product
--How many units of each coffee product have been sold?
select p.product_id,sum(total) as total_units from products as p
join sales as s
on p.product_id=s.product_id
group by 1;
--City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.
select c.city_id,city_name,(0.25)*population as coffee_consumers,count(distinct customer_id) as unique_consumers from customers as c
join city as ct
on c.city_id=ct.city_id
group by 1,2,3
--Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?
with cte as (select city_name,product_id,sum(total) as quantity_sold,dense_rank() over(partition by city_name order by sum(total)) as ranks from sales as s
join customers as c
on s.customer_id=c.customer_id
join city as ct
on c.city_id=ct.city_id
group by 1,2 order by 1)
select * from cte where ranks<=3;
--Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?
select c.city_id,city_name,count(distinct customer_id) as unique_consumers from customers as c
join city as ct
on c.city_id=ct.city_id
group by 1,2
--Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer
with cte as(select city_name,sum(total)/(count(distinct c.customer_id)) as avg_sale_per_customer,count(distinct c.customer_id) as unique_count from sales as s
join products as p
on s.product_id=p.product_id
join customers as c
on s.customer_id=c.customer_id
join city as ct 
on c.city_id=ct.city_id
group by 1)
select c.city_name,avg_sale_per_customer,estimated_rent/unique_count as avg_rent from cte as c
join city as ct
on c.city_name=ct.city_name
--Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) 
--in sales over different time periods (monthly).
with cte as(
select extract(year from sale_date) as Year_, extract(month from sale_date) 
as Months,lag(total) over( partition by extract(year from sale_date) 
order by extract(month from sale_date)) as prev_total,total from sales)
select *,round((this_month_sale::numeric/prev_month_sale),5) as ratio from(select Year_, Months,sum(prev_total) as prev_month_sale,sum(total) as this_month_sale from cte
group by 1,2) as new_data
--Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, 
--total rent, total customers, estimated coffee consumer
with cte as(select city_name,sum(total)/(count(distinct c.customer_id)) as avg_sale_per_customer,count(distinct c.customer_id) as unique_count from sales as s
join products as p
on s.product_id=p.product_id
join customers as c
on s.customer_id=c.customer_id
join city as ct 
on c.city_id=ct.city_id
group by 1)
select c.city_name,avg_sale_per_customer,estimated_rent/unique_count as avg_rent, (0.25)*population as coffee_consumers,unique_count
from cte as c
join city as ct
on c.city_name=ct.city_name