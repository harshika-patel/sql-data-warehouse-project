/*
metadata columns:extra columns added by data engineer that do not originate from the source data
create_date:the record's load Timestamp
update_date:the record's last update timestamp
source system:the origin system of the record
file_location:the file source of the record*/

-- checking quality issues
/*extra spaces before and after name in cst_firstname and cst_lastanme
cst_gender is null
cst_id-null for 3 rows almost all col null some data for cst_key

prdline value null
prd_end_dt null
prd_key -naming inconsistancy
prd_nm also inconsistant
*/
select  * from bronze.crm_cust_info
select DISTINCT  * from bronze.crm_cust_info

select * from bronze.crm_prd_info
select DISTINCT * from bronze.crm_prd_info

select  * from bronze.crm_sales_details
select * from bronze.erp_cust_az12
--gender in full name -either make short here ot there cust_info table
--null values
select * from bronze.erp_loc_a101
--cntry name make it full for example US-inconsist
select * from bronze.erp_px_cat_g1v2
----above is my observation----------------

--check for nulls or duplicates in primary key
--Expectation:no result

select  cst_id,count(cst_id) from bronze.crm_cust_info
group by cst_id
having count(cst_id)>1---here we find duplicate cst_id and null also

--check for unwanted spaces bronze.crm_cust_info
select cst_firstname from bronze.crm_cust_info
where cst_firstname!=trim(cst_firstname) 

select cst_lastname from bronze.crm_cust_info
where cst_lastname!=trim(cst_lastname) 

select cst_gndr from bronze.crm_cust_info
where cst_gndr!=trim(cst_gndr) 

select cst_marital_status from bronze.crm_cust_info
where cst_marital_status!=trim(cst_marital_status) 

select DISTINCT cst_gndr from bronze.crm_cust_info
select DISTINCT cst_marital_status from bronze.crm_cust_info
-------------------------------------------------------
---------------------------------------------------------------------

truncate table silver.crm_cust_info

insert into silver.crm_cust_info(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
select 
    cst_id,
    cst_key,
    trim(cst_firstname) as cst_firstname,
    trim(cst_lastname) as cst_lastname,
    case when upper(trim(cst_marital_status))='M' then 'Married'
         when upper(trim(cst_marital_status))='S' then 'Single'
         else 'n/a'
    end as cst_marital_status,
    case when upper(trim(cst_gndr))='F' then 'Female'
         when upper(trim(cst_gndr))='M' then 'Male'
         else 'n/a'
    end as cst_gndr,
    cst_create_date
from
    (select *,
    DENSE_RANK() over(partition by cst_id order by cst_create_date desc) flag_last
    from bronze.crm_cust_info 
    where cst_id is not null )t
where flag_last=1

select * from silver.crm_cust_info
-----------------------------------------------------------------
--After inserting all good data in silver we check the same query which we check before in bronze table but
--now we check with new data in silver and 
--expected result - should be empty for all
--because we do transformation
select  cst_id,count(cst_id) from silver.crm_cust_info
group by cst_id
having count(cst_id)>1 or cst_id is null---No result is found

--check for unwanted spaces bronze.crm_cust_info
select cst_firstname from silver.crm_cust_info
where cst_firstname!=trim(cst_firstname) --no result in found in silver table

select cst_lastname from silver.crm_cust_info
where cst_lastname!=trim(cst_lastname) 

select cst_gndr from silver.crm_cust_info
where cst_gndr!=trim(cst_gndr) 

select cst_marital_status from silver.crm_cust_info
where cst_marital_status!=trim(cst_marital_status) 

select DISTINCT cst_gndr from silver.crm_cust_info
select DISTINCT cst_marital_status from silver.crm_cust_info
--all look good and cleaned
/*
here we did different type of data transformation
1.remove unwanted spaces using trim-removes unnecessary spaces to ensure data consistency and uniformity
      across all records
2.data normalization and standardization:
Maps coded values to meaningful,user-freindly descriptions
3.handle missing data: fills in the blanks by adding default value
4.Remove duplicate: ensure only one record per entity by identifying and retaining the most relevant row.
5.data filtering to
*/

select * from bronze.crm_prd_info

select prd_id,count(prd_id) from bronze.crm_prd_info
group by prd_id
having count(prd_id)>1 or prd_id is null

select prd_key,count(prd_key) from bronze.crm_prd_info
group by prd_key
having count(prd_key)>1

select * from(select *,rank() over (partition by prd_key order by prd_start_dt desc) as flag_first
from bronze.crm_prd_info)t 
where flag_first>=1

select prd_id,
prd_key,
replace(substring (prd_key,1,5),'-','_') cat_id,
substring (prd_key,7,len(prd_key)) sls_prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
from bronze.crm_prd_info 
where  replace(substring (prd_key,1,5),'-','_') in 
(select id from bronze.erp_px_cat_g1v2)--here we check varified how many match and not match 
--same we do for sls_prd_key

--check unwanted space in Prd_nm
select * from bronze.crm_prd_info
where prd_nm!=trim(prd_nm)--no value found so all good
select * from bronze.crm_prd_info
where prd_key!=trim(prd_key)----no value found so all good
select * from bronze.crm_prd_info
where prd_line!=trim(prd_line)----no value found so all good

--for numb we check we have null and or negative num
select *,
case when prd_cost is not null then prd_cost
     else 0
end as prd_cost
from bronze.crm_prd_info
where prd_cost< 0 or prd_cost is null--there us no negative vaule but null found

--data standardization and cosistency
select distinct prd_line from bronze.crm_prd_info

--now check in Prd_start_dt has null value
select * from bronze.crm_prd_info where prd_start_dt is null
select *,
isnull(prd_end_dt,'n/a')
from bronze.crm_prd_info where prd_end_dt is null

--now we check the date is coorect or not
--for example start date is always earlier than end date 

select * from bronze.crm_prd_info where prd_start_dt > prd_end_dt--but here start dt is 2011 
--where end is 2007 that is wrong if it start 2011 than may be end 2012 or later month of 2011
--so correct this one 
select * ,prd_start_dt,lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) prd_end_dt
from bronze.crm_prd_info where  prd_end_dt <  prd_start_dt and prd_key in ('AC-HE-HL-U509-R','AC-HE-HL-U509')
---------------------------------------------

truncate table silver.crm_prd_info
insert into silver.crm_prd_info(
prd_id ,
cat_id ,
prd_key ,
prd_nm ,
prd_cost ,
prd_line ,
prd_start_dt ,
prd_end_dt 

)
select prd_id,
replace(substring (prd_key,1,5),'-','_') cat_id,--here we create a new columns--create bew columns
--based on calculations or transformation of existing ones-derived columns
substring (prd_key,7,len(prd_key)) prd_key,
prd_nm,
isnull(prd_cost,0) prd_cost,--handling null values and replace with 0 
case when upper(trim(prd_line))='M' then 'Mountain'
     when upper(trim(prd_line))='R' then 'Road'
     when upper(trim(prd_line))='S' then 'Other Sales'
     when upper(trim(prd_line))='T' then 'Touring'
     else 'n/a'--handle missing data
end as prd_line,-- above we did data noprmalization
cast (prd_start_dt as date)as prd_start_dt,--here we did datatype casting

cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) as date)as prd_end_dt
--this is called data enrichment- add new ,relevant data to enhance the dataset for analysis
from bronze.crm_prd_info 

--------------------------------------------------

select * from silver.crm_prd_info
--=======================================================================================
------after Data clean up check all queries in silver table which has issue in bronze but not in 
--silver table
--=======================================================================================


select prd_id,count(prd_id) from silver.crm_prd_info
group by prd_id
having count(prd_id)>1 or prd_id is null

select prd_id,
prd_key,
replace(substring (prd_key,1,5),'-','_') cat_id,
substring (prd_key,7,len(prd_key)) sls_prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
from silver.crm_prd_info 
where  replace(substring (prd_key,1,5),'-','_') in 
(select id from bronze.erp_px_cat_g1v2)--here we check varified how many match and not match 
--same we do for sls_prd_key

--check unwanted space in Prd_nm
select * from silver.crm_prd_info
where prd_nm!=trim(prd_nm)--no value found so all good
select * from silver.crm_prd_info
where prd_key!=trim(prd_key)----no value found so all good
select * from silver.crm_prd_info
where prd_line!=trim(prd_line)----no value found so all good

--for numb we check we have null and or negative num
select *,
case when prd_cost is not null then prd_cost
     else 0
end as prd_cost
from silver.crm_prd_info
where prd_cost< 0 or prd_cost is null--there us no negative vaule but null found

--data standardization and cosistency
select distinct prd_line from silver.crm_prd_info

--now check in Prd_start_dt has null value
select * from bronze.crm_prd_info where prd_start_dt is null
select *,
isnull(prd_end_dt,'n/a')
from silver.crm_prd_info where prd_end_dt is null

--now we check the date is coorect or not
--for example start date is always earlier than end date 

select * from silver.crm_prd_info where prd_start_dt > prd_end_dt--but here start dt is 2011 
--where end is 2007 that is wrong if it start 2011 than may be end 2012 or later month of 2011
--so correct this one 
select * ,prd_start_dt,lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) prd_end_dt
from silver.crm_prd_info 
where  prd_end_dt <  prd_start_dt and prd_key in ('AC-HE-HL-U509-R','AC-HE-HL-U509')
--all is good so move to next table
--==============================================================================
--Now load and clean data Crm.sales_details
select * from bronze.crm_sales_details
where sls_price < 0 or sls_price is null

select * from bronze.crm_sales_details
where sls_quantity < 0 or sls_quantity is null--this perfect

select * from bronze.crm_sales_details
where sls_ord_num is null or trim(sls_ord_num)!=sls_ord_num--this work perfectly

select * from bronze.crm_sales_details
where sls_prd_key is null or trim(sls_prd_key)!=sls_prd_key

select * from bronze.crm_sales_details
where sls_cust_id is null

select * from bronze.crm_sales_details
where sls_prd_key not in(select prd_key from silver.crm_prd_info)

select * from bronze.crm_sales_details
where sls_cust_id not in(select cst_id from silver.crm_cust_info)

select  nullif(sls_order_dt,0) 
from bronze.crm_sales_details
where sls_order_dt<=0 or len(sls_order_dt)!=8
or sls_order_dt >20500101--here we check bountries
or sls_order_dt <19000101

select * from bronze.crm_sales_details
where sls_ship_dt<=0
select * from bronze.crm_sales_details
where sls_due_dt< =0

select * from bronze.crm_sales_details
where sls_order_dt> sls_ship_dt or sls_order_dt>sls_due_dt

--Business Rules
--sales=quanity*price , 
--negtaive ,zeros , null are not allowed
select  
sls_price,
sls_sales as old_sales,
sls_quantity,
case when sls_quantity*abs(sls_price)!=sls_sales or sls_sales<=0 or sls_sales is null
     then  sls_quantity*abs(sls_price)
     else sls_sales
end sls_sales,
case when sls_price <= 0 or sls_price is null 
      then sls_sales/nullif(sls_quantity,0)
      else sls_price
end sls_price
from bronze.crm_sales_details
where sls_quantity*sls_price!=sls_sales
or sls_quantity is null or sls_price is null or sls_sales is null
or sls_quantity <= 0 or sls_price <= 0 or sls_sales <= 0
----------------------------------------------------

truncate table silver.crm_sales_details
insert into silver.crm_sales_details(
sls_ord_num ,
sls_prd_key ,
sls_cust_id ,
sls_order_dt ,
sls_ship_dt ,
sls_due_dt ,
sls_sales ,
sls_quantity ,
sls_price
)
select sls_ord_num,
sls_prd_key,
sls_cust_id,
case when sls_order_dt=0 or len(sls_order_dt)!=8 then null--handle invalid data
      else cast(cast (sls_order_dt as varchar) as date)--data converting
end as sls_order_dt,
case when sls_ship_dt=0 or len(sls_ship_dt)!=8 then null
      else cast(cast (sls_ship_dt as varchar) as date)
end as sls_ship_dt,
case when sls_due_dt=0 or len(sls_due_dt)!=8 then null
      else cast(cast (sls_due_dt as varchar) as date)
end as sls_due_dt,
case when sls_quantity*abs(sls_price)!=sls_sales or sls_sales<=0 or sls_sales is null
     then  sls_quantity*abs(sls_price)
     else sls_sales
end sls_sales,--recalculates sales if original value is missing or incorrect
sls_quantity,
case when sls_price <= 0 or sls_price is null 
      then sls_sales/nullif(sls_quantity,0)
      else sls_price
end sls_price--derived price if original value is invalid

from bronze.crm_sales_details


----------------------------------------------------

--now check in silver table after cleaning up data
--Now load and clean data Crm.sales_details
select * from silver.crm_sales_details
where sls_price < 0 or sls_price is null

select * from silver.crm_sales_details
where sls_quantity < 0 or sls_quantity is null--this perfect

select * from silver.crm_sales_details
where sls_ord_num is null or trim(sls_ord_num)!=sls_ord_num--this work perfectly

select * from silver.crm_sales_details
where sls_prd_key is null or trim(sls_prd_key)!=sls_prd_key

select * from silver.crm_sales_details
where sls_cust_id is null

select * from silver.crm_sales_details
where sls_prd_key not in(select prd_key from silver.crm_prd_info)

select * from silver.crm_sales_details
where sls_cust_id not in(select cst_id from silver.crm_cust_info)

select  nullif(sls_order_dt,0) 
from silver.crm_sales_details
where sls_order_dt<=0 or len(sls_order_dt)!=8
or sls_order_dt >20500101--here we check bountries
or sls_order_dt <19000101

select * from silver.crm_sales_details
where sls_ship_dt<=0
select * from silver.crm_sales_details
where sls_due_dt< =0

select * from siver.crm_sales_details
where sls_order_dt> sls_ship_dt or sls_order_dt>sls_due_dt

--Business Rules
--sales=quanity*price , 
--negtaive ,zeros , null are not allowed
select  
sls_price,
sls_sales,
sls_quantity
from silver.crm_sales_details
where sls_quantity*sls_price!=sls_sales
or sls_quantity is null or sls_price is null or sls_sales is null
or sls_quantity <= 0 or sls_price <= 0 or sls_sales <= 0

select * from silver.crm_sales_details
--=======================================================
/*
Clean and load Data in sliver layer 
for Erp cust az12
*/
--======================================================
select distinct cid from bronze.erp_cust_az12
select cid from bronze.erp_cust_az12
where trim(cid)!=cid
select bdate from bronze.erp_cust_az12
where bdate>=getdate() or bdate<'1924-01-01'
select distinct gen from(select case when Upper(gen)in ('F','FEMALE')  then 'Female'
            when Upper(gen)in ('M' , 'MALE') then 'Male'
            else 'n/a'
         end gen
from bronze.erp_cust_az12)t
-----------------------------------------------------

truncate table silver.erp_cust_az12
insert into silver.erp_cust_az12 (cid,bdate,gen)
select 
case when cid like 'NAS%' then substring(cid,4,len(cid))
     else cid
end cid,
case when bdate>=getdate() then null
      else bdate
end as bdate,
case when Upper(gen)in ('F','FEMALE')  then 'Female'
            when Upper(gen)in ('M' , 'MALE') then 'Male'
            else 'n/a'
end gen
from bronze.erp_cust_az12
---------------------------------------------------------------------------------------

--now check data quality above query but now in silver
select distinct cid from silver.erp_cust_az12
select cid from silver.erp_cust_az12
where trim(cid)!=cid
select bdate from silver.erp_cust_az12
where bdate>=getdate() 
select distinct gen from(select case when Upper(gen)in ('F','FEMALE')  then 'Female'
            when Upper(gen)in ('M' , 'MALE') then 'Male'
            else 'n/a'
         end gen
from silver.erp_cust_az12)t
--all is good in silver erp cust_az12 data
---------------------------------

---now clean and laod erp_loc_a101
select * from bronze.erp_loc_a101

select distinct cid from bronze.erp_loc_a101
select cid from bronze.erp_loc_a101
where trim(cid)!=cid

select * from(select trim(substring(cid,1,2))+trim(SUBSTRING(cid,4,len(cid))) cid
from bronze.erp_loc_a101)t
where cid  in (select cst_key from silver.crm_cust_info)

select * from(select substring(cid,1,2)+SUBSTRING(cid,4,len(cid)) cid
from bronze.erp_loc_a101)t
where cid  in (select cid from silver.erp_cust_az12)

select distinct cntry from(select case when upper(trim(cntry)) in ('USA','US','United States') then 'United States'
            when upper(trim(cntry)) IN ('DE', 'GERMANY') THEN 'Germany'
            when upper(trim(cntry)) in ('France') then 'France'
             when upper(trim(cntry)) in ('Canada') then 'Canada'
              when upper(trim(cntry)) in ('Australia') then 'Australia'
               when upper(trim(cntry)) in ('United Kingdom') then 'United Kingdom'
            else 'n/a'
        end cntry
from bronze.erp_loc_a101)t


-----------------------------------------------------------------------------------------
truncate table silver.erp_loc_a101
insert into silver.erp_loc_a101(cid,cntry)
select 
trim(replace(cid,'-','')) cid,
case when upper(trim(cntry)) in ('USA','US','United States') then 'United States'
            when upper(trim(cntry)) IN ('DE', 'GERMANY') THEN 'Germany'
            when upper(trim(cntry)) in ('France') then 'France'
             when upper(trim(cntry)) in ('Canada') then 'Canada'
              when upper(trim(cntry)) in ('Australia') then 'Australia'
               when upper(trim(cntry)) in ('United Kingdom') then 'United Kingdom'
            else 'n/a'
        end cntry 
from bronze.erp_loc_a101
--------------------------------------------------------------------------------------
select * from silver.erp_loc_a101
---now check in silver 

select cntry from
 silver.erp_loc_a101 where cntry is null

 select cid from
 silver.erp_loc_a101 where cid != trim(cid) or cid is null--all work perfect
 -------------------------------------------------------------------------------------
 --now clean and load in px_cat_g1v2
 select * from bronze.erp_px_cat_g1v2

select id from bronze.erp_px_cat_g1v2 where id !=trim(id) or id is null
select cat from bronze.erp_px_cat_g1v2 where cat !=trim(cat) or cat is null
select subcat from bronze.erp_px_cat_g1v2 where subcat !=trim(subcat) or subcat is null
select maintenance from bronze.erp_px_cat_g1v2 where maintenance !=trim(maintenance) or maintenance is null
select id from bronze.erp_px_cat_g1v2 where id in (select cat_id from silver.crm_prd_info)
select distinct cat from bronze.erp_px_cat_g1v2
select distinct subcat from bronze.erp_px_cat_g1v2
select distinct maintenance from bronze.erp_px_cat_g1v2

------------------------------------------------------------------------------------
truncate table silver.erp_px_cat_g1v2
insert into silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
select id,cat,subcat,maintenance from bronze.erp_px_cat_g1v2
--------------------------------------------------------------------------------------
select * from silver.erp_px_cat_g1v2
