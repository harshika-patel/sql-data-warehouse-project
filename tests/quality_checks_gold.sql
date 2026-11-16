*/
--build gold layer
--create dimesion Customers
--so three table containe customer info cust_info,cust_az12,loc_a101--this thrree as customer data so we join these 3 tables
-- and master table also join with left join so we did not loose any data from the master tables

select ci.cst_id,ci.cst_key,ci.cst_firstname,ci.cst_lastname,ci.cst_marital_status,ci.cst_gndr,ci.cst_create_date,
ca.bdate,ca.gen,
la.cntry
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca on ci.cst_key=ca.cid
left join silver.erp_loc_a101 la on ci.cst_key=la.cid

---now we check we have any duplicate cst_id 
select cst_id,count(cst_id) from(
select ci.cst_id,ci.cst_key,ci.cst_firstname,ci.cst_lastname,ci.cst_marital_status,ci.cst_gndr,ci.cst_create_date,
ca.bdate,ca.gen,
la.cntry
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca on ci.cst_key=ca.cid
left join silver.erp_loc_a101 la on ci.cst_key=la.cid)t
group by cst_id
having count(cst_id)>1--everything is perfect no data found

-----we have two gender cols fist cst_gnde, ca.gen so what we do keep up one before we do data integration
select distinct ci.cst_gndr,
ca.gen,
case when ci.cst_gndr!='n/a' then ci.cst_gndr
     else coalesce(ca.gen,'n/a')
end as new_gndr
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca on ci.cst_key=ca.cid
left join silver.erp_loc_a101 la on ci.cst_key=la.cid
order by 1,2

---give good name to columns and reorder all cols
select ci.cst_id as customer_id,
ci.cst_key as customer_number,
ci.cst_firstname as first_name,
ci.cst_lastname as last_name,
la.cntry as country,
ci.cst_marital_status as marital_status,
case when ci.cst_gndr!='n/a' then ci.cst_gndr
     else coalesce(ca.gen,'n/a')
end as gender,
ca.bdate as birthdate,
ci.cst_create_date as create_date
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca on ci.cst_key=ca.cid
left join silver.erp_loc_a101 la on ci.cst_key=la.cid

--this table is dimestions or facts?
--it has all data about customer info so it is dimesions

--surrogate key:-system-generated unique identifier assigned to each record in a table
--DDL based generation
--query based using window functions(row_number)
--now create a view

--now quality check of the gold table
select * from gold.dim_customers

select customer_key, count(customer_key) from gold.dim_customers 
group by customer_key
having count(customer_key) > 1 or customer_key is null

select customer_id, count(customer_id) from gold.dim_customers 
group by customer_id
having count(customer_id) > 1 or customer_id is null

select customer_number, count(customer_number) from gold.dim_customers 
group by customer_number
having count(customer_number) > 1 or customer_number is null

select first_name from gold.dim_customers
where first_name !=trim(first_name) or first_name is null

select last_name from gold.dim_customers
where last_name !=trim(last_name) or last_name is null

select country from gold.dim_customers
where country !=trim(country) or country is null
select distinct country  from gold.dim_customers

select gender from gold.dim_customers
where gender !=trim(gender) or gender is null

select distinct gender from gold.dim_customers

select marital_status from gold.dim_customers
where marital_status !=trim(marital_status) or marital_status is null
select distinct marital_status from gold.dim_customers

select birthdate from gold.dim_customers
where birthdate is null or birthdate> getdate()

select create_date from gold.dim_customers
where create_date is null or create_date> getdate()
/*-------------------------------next for products tables-------------------*/


select prd_key,count(prd_key)--all prd_key is unique
from(select 
pi.prd_id,
pi.cat_id,
pi.prd_key,
pi.prd_nm,
pi.prd_cost,
pi.prd_line,
pi.prd_start_dt,
pcg.cat,
pcg.subcat,
pcg.maintenance
from silver.crm_prd_info pi
left join silver.erp_px_cat_g1v2 pcg 
on pi.cat_id=pcg.id
where pi.prd_end_dt is null )t
group by prd_key
having count(prd_key)>1


---check the quality of fact sales 
select * from gold.fact_sales f
left join gold.dim_customers c on
f.customer_key=c.customer_key
left join gold.dim_products p on
p.product_key=f.product_key
where f.product_key is null--no data found 
