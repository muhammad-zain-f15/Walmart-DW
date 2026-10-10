/*
Schema of DW
*/

DROP TABLE if exists dim_customer;
CREATE TABLE dim_customer
(
	customer_id nvarchar(50) primary key,
	gender nvarchar(10),
	age nvarchar(50),
	occupation nvarchar(50),
	city_category nvarchar(10),
	stay_in_current_city_years nvarchar(50),
	marital_status nvarchar(50)
);

alter table dim_customer
alter column occupation int;

alter table dim_customer
alter column stay_in_current_city_years int;

DROP TABLE IF EXISTS dim_store;
CREATE TABLE dim_store
(
	store_id nvarchar(50) primary key,
	store_name nvarchar(50)
);



DROP TABLE IF EXISTS dim_supplier;
CREATE TABLE dim_supplier
(
	supplier_id nvarchar(50) primary key,
	supplier_name nvarchar(50)
);

DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product
(
	product_id varchar(50) primary key,
	product_cat nvarchar(50),
	price decimal(10,2),
	store_id nvarchar(50),
	supplier_id nvarchar(50),
	constraint store_product_fk
	foreign key (store_id) references dim_store(store_id),
	constraint supplier_product_fk
	foreign key (supplier_id) references dim_supplier(supplier_id)
);


DROP TABLE if exists fact_sale;
CREATE TABLE fact_sale
(
	order_id int primary key,
	customer_id nvarchar(50),
	product_id varchar(50),
	store_id nvarchar(50),
	supplier_id nvarchar(50),
	order_date date,
	quantity int,
	sale_amount decimal(10,2),
	constraint customer_sale_fk
	foreign key (customer_id) references dim_customer(customer_id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	constraint product_sale_fk
	foreign key (product_id) references dim_product(product_id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	constraint store_sale_fk
	foreign key (store_id) references dim_store(store_id)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
	constraint supplier_sale_fk
	foreign key (supplier_id) references dim_supplier(supplier_id)
	ON DELETE CASCADE
	ON UPDATE CASCADE


);
