

/*
	load data from master_customer table to dim_customer table
*/

select * from dbo.customer_master_data;

INSERT INTO dim_customer
select
cast(customer_id as nvarchar(50)) as customer_id,
case gender
when'M' then 'Male'
else 'Female'
end as gender,
age,
cast (occupation as int) as occupation,
city_category,
cast(stay_in_current_city_years as int) stay_in_current_city_years,
case marital_status
when 0 then 'Unmarried'
else 'Married' end as marital_status
from dbo.customer_master_data;


select * from dim_customer;

select * from dbo.product_master_data;


INSERT INTO dim_store
select distinct
	cast (storeid as int) as store_id,
	storename as store_name
from dbo.product_master_data
order by store_id;

INSERT INTO dim_supplier
select distinct
	cast (supplierid as int) as supplier_id,
	suppliername as supplier_name
from dbo.product_master_data
order by supplier_id;

INSERT INTO dim_product
select
	product_id,
	product_category,
	cast (price as decimal(10,2)) as price,
	storeid as store_id,
	supplierid as supplier_id
from dbo.product_master_data

INSERT INTO fact_sale
SELECT
orderid ,
t.customer_id,
t.product_id ,
s.store_id,
sp.supplier_id,
date ,
quantity,
quantity * p.price as sale_amount
FROM dbo.transactional_data t
INNER JOIN dim_product p
ON t.product_id = p.product_id
INNER JOIN dim_store s
ON p.store_id = s.store_id
INNER JOIN dim_supplier as sp
ON p.supplier_id = sp.supplier_id;
