
-- time analysis
select distinct
	year(order_date) as year,
	month(order_date) as month
from fact_sale
order by year(order_date),month(order_date);
/*
Q1. Top Revenue-Generating Products on Weekdays and Weekends with Monthly DrillDown 
Identifies the top 5 products by revenue, split by weekdays and weekends, with monthly breakdowns for a year
*/

/* Top products By weekday revenue*/
with day_type_cte as
(
select
product_id,
DATEPART(year,order_date) as year,
DATEPART(month,order_date) as month,
case when DATEPART(dw,order_date) >5 then 'WeekDay'
else 'Weekend'
end as day_type,
sale_amount
from fact_sale
),
product_revenue_cte as
(
	select
	product_id,
	year,
	month,
	sum(case when day_type = 'WeekDay' then sale_amount else 0 end) as weekday_revenue,
	sum(case when day_type = 'Weekend' then sale_amount else 0 end) as weekend_revenue
	from  day_type_cte
	group by year,month, product_id
	
),
ranked_revenue_cte as
(
select *,
row_number() over(partition by year,month order by weekday_revenue desc, weekend_revenue desc) as rn
from product_revenue_cte

)
select
product_id,
year,
month,
weekday_revenue,
weekend_revenue 
from ranked_revenue_cte
where rn <=5
order by year,month,rn;

/*Top products By weekend revenue*/
with day_type_cte as
(
select
product_id,
DATEPART(year,order_date) as year,
DATEPART(month,order_date) as month,
case when DATEPART(dw,order_date) >5 then 'WeekDay'
else 'Weekend'
end as day_type,
sale_amount
from fact_sale
),
product_revenue_cte as
(
	select
	product_id,
	year,
	month,
	sum(case when day_type = 'WeekDay' then sale_amount else 0 end) as weekday_revenue,
	sum(case when day_type = 'Weekend' then sale_amount else 0 end) as weekend_revenue
	from  day_type_cte
	group by year,month, product_id
	
),
ranked_revenue_cte as
(
select *,
row_number() over(partition by year,month order by weekend_revenue desc, weekday_revenue desc) as rn
from product_revenue_cte

)
select
product_id,
year,
month,
weekday_revenue,
weekend_revenue 
from ranked_revenue_cte
where rn <=5
order by year,month,rn;


/*
	Q2. Customer Demographics by Purchase Amount with City Category Breakdown
Analyzes total purchase amounts by gender and age, detailed by city category.
*/

select

SELECT
	city_category,
	gender,
	age,
	sum(sale_amount) as total_purchase_amount
FROM fact_sale f
inner join dim_customer c 
on f.customer_id = c.customer_id
GROUP BY city_category, gender,age
order by city_category,total_purchase_amount desc;

/*
	Q3. Product Category Sales by Occupation
Examines total sales for each product category based on customer occupation.
*/
select
p.product_cat as product_category,
c.occupation as customer_occupation,
sum(sale_amount) as total_sales
from fact_sale f
inner join dim_customer c
ON f.customer_id = c.customer_id
inner join dim_product p
ON f.product_id = p.product_id
group by c.occupation,p.product_cat
order by product_category, total_sales desc;

/*
 Q4. Total Purchases by Gender and Age Group with Quarterly Trend
Tracks purchase amounts by gender and age across quarterly periods for the current year
*/
SELECT
	DATEPART(year,order_date) as year,
	DATEPART(quarter,order_date) as quarter,
	gender,
	age,
	sum(sale_amount) as total_purchase_amount
FROM fact_sale f
INNER JOIN dim_customer c 
ON f.customer_id = c.customer_id
GROUP BY DATEPART(year,order_date),DATEPART(quarter,order_date), gender,age
ORDER BY year,quarter,total_purchase_amount desc;

/*
Q5. Top Occupations by Product Category Sales
Highlights the top 5 occupations driving sales within each product category
*/
with cte as
(
select
p.product_cat as product_category,
c.occupation as customer_occupation,
sum(sale_amount) as total_sales,
ROW_NUMBER() over(partition by product_cat order by sum(sale_amount) desc) as rn
from fact_sale f
inner join dim_customer c
ON f.customer_id = c.customer_id
inner join dim_product p
ON f.product_id = p.product_id
group by c.occupation,p.product_cat)
select * from cte where rn <= 5

/*
Q6. City Category Performance by Marital Status with Monthly Breakdown
Assesses purchase amounts by city category and marital status over the past 6 months.
*/

select 
	city_category,
	marital_status,
	sum(sale_amount) as total_purchase_amount
from fact_sale f
inner join dim_customer c
on f.customer_id = c.customer_id
where order_date > dateadd(month ,-6,(select max(order_date) from fact_sale))
group by city_category, marital_status
order by city_category, total_purchase_amount desc;

/*
	Q7. Average Purchase Amount by Stay Duration and Gender
Calculates the average purchase amount based on years stayed in the city and gender
*/

SELECT
	stay_in_current_city_years,
	gender,
	AVG(sale_amount) as average_purchase_amount
FROM fact_sale f 
INNER JOIN dim_customer c 
ON f.customer_id = c.customer_id
GROUP BY stay_in_current_city_years, gender
ORDER BY stay_in_current_city_years,average_purchase_amount desc;

/*
	Q8. Revenue Cities by Product Category
Ranks the city categories by revenue, grouped by product category
*/

SELECT
	p.product_cat,
	c.city_category,
	sum(sale_amount) as revenue,
	row_number() over(partition by p.product_cat order by sum(sale_amount) desc) as rn
FROM fact_sale f 
INNER JOIN dim_customer c 
ON f.customer_id = c.customer_id 
INNER JOIN dim_product p
ON f.product_id = p.product_id
GROUP BY p.product_cat, c.city_category;

/*
	Q9. Monthly Sales Growth by Product Category
Measures month-over-month sales growth percentage for each product category in the current
year.
*/
with cte as
(
SELECT
	year(order_date) as year,
	month(order_date) as month,
	product_cat,
	sum(sale_amount) current_month_sale,
	lag(sum(sale_amount)) over(partition by year(order_date),product_cat order by month(order_date)) as previous_month_sale
FROM fact_sale f
INNER JOIN dim_product p 
ON f.product_id = p.product_id
group by year(order_date), month(order_date),product_cat
)
select
*,
cast (round(((current_month_sale*1.0-previous_month_sale)/previous_month_sale)*100,2) as decimal(10,2)) as mom_per
from cte;


/*

Q10. Weekend vs. Weekday Sales by Age Group
Compares total sales by age group for weekends versus weekdays in the current year.
*/
with cte as
(
SELECT
	year(order_date) as year,
	case when DATEPART(dw,order_date) >5 then 'WeekDay'
	else 'Weekend'
	end as day_type,
	age,
	sale_amount
FROM fact_sale f
inner join dim_customer c
ON f.customer_id = c.customer_id
)
select
year,
day_type,
age,
sum(sale_amount) total_sales_by_age_group
from cte 
group by year,day_type,age
order by year,age,total_sales_by_age_group desc ;

/*
Q11. Top Revenue-Generating Products on Weekdays and Weekends with Monthly DrillDown
Find the top 5 products that generated the highest revenue, separated by weekday and
weekend
sales, with results grouped by month for a specified year.

*/

with day_type_cte as
(
select
product_id,
DATEPART(year,order_date) as year,
DATEPART(month,order_date) as month,
case when DATEPART(dw,order_date) >5 then 'WeekDay'
else 'Weekend'
end as day_type,
sale_amount
from fact_sale
where DATEPART(year,order_date) = 2015
),
product_revenue_cte as
(
	select
	product_id,
	year,
	month,
	sum(case when day_type = 'WeekDay' then sale_amount else 0 end) as weekday_revenue,
	sum(case when day_type = 'Weekend' then sale_amount else 0 end) as weekend_revenue
	from  day_type_cte
	group by year,month, product_id
	
),
ranked_revenue_cte as
(
select *,
row_number() over(partition by year,month order by weekday_revenue desc, weekend_revenue desc) as rn
from product_revenue_cte

)
select
product_id,
year,
month,
weekday_revenue,
weekend_revenue 
from ranked_revenue_cte
where rn <=5
order by year,month,rn;





/*
Q12. Trend Analysis of Store Revenue Growth Rate Quarterly for 2017
Calculate the revenue growth rate for each store on a quarterly basis for 2017.
*/
with cte as
(
select
	store_name,
	datepart(quarter,order_date) as q_no,
	sum(sale_amount) as current_q_sale,
	lag(sum(sale_amount)) over(partition by store_name order by datepart(quarter,order_date)) as previous_q_sale
from fact_sale f
inner join dim_store s
ON f.store_id = s.store_id
where DATEPART(year,order_date) = 2017
group by store_name,datepart(quarter,order_date)
)
SELECT
*,
cast (round((current_q_sale-previous_q_sale)*100.0/previous_q_sale,2) as decimal(10,2)) as q_over_q
FROM cte;


/*
	Q13. Detailed Supplier Sales Contribution by Store and Product Name
For each store, show the total sales contribution of each supplier broken down by product
id. The output should group results by store, then supplier, and then product name under
each supplier.
*/

SELECT
	s.store_name,
	sp.supplier_name,
	p.product_id,
	sum(sale_amount) as total_sale
FROM fact_sale f
INNER JOIN dim_store s
ON f.store_id = s.store_id
INNER JOIN dim_supplier sp
on f.supplier_id = sp.supplier_id
INNER JOIN dim_product p
ON f.product_id = p.product_id
GROUP BY s.store_name,sp.supplier_name,p.product_id
ORDER BY store_name,supplier_name,total_sale desc;

/*
Q14. Seasonal Analysis of Product Sales Using Dynamic Drill-Down
Present total sales for each product, drilled down by seasonal periods (Spring, Summer, Fall,
Winter). This can help understand product performance across seasonal periods.
*/
with cte as
(
	select
		product_id,
		case 
			when DATEPART(month,order_date) BETWEEN 3 AND 5 then 'Spring'
			when DATEPART(month,order_date) BETWEEN 6 AND 8 then 'Summer'
			when DATEPART(month,order_date) BETWEEN 9 AND 10 then 'Autumn'
			else 'Winter'
		end as season,
		sale_amount
	from fact_sale
)
select
	season,
	product_id,
	sum(sale_amount) as sale_amount
from cte
group by season, product_id
ORDER BY season;
