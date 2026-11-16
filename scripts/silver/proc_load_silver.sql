--usage example
--exec silver.load_silver;

create or alter procedure silver.load_silver as
begin
    declare @start_time datetime, @end_time datetime,@batch_start_time datetime,@batch_end_time datetime
    begin try
    set @batch_start_time=getdate()
        print '==================================='
        print 'Loading silver Layer'
        print '==================================='
        print '----------------------Loading CRM tables-----------------------------'


        set @start_time=getdate()
        print '>> Truncating Table: silver.crm_cust_info'
        truncate table silver.crm_cust_info
        print '>> Inserting Data: silver.crm_cust_info '
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
        set @end_time=getdate()
        print 'Query proceesing time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds'
        print('----------------------------------------------------------------')
        print(' ')
        print(' ')
        -----------------------------------------------------------------------
        set @start_time=getdate();
        print '>> Truncating Table: silver.crm_prd_info'
        truncate table silver.crm_prd_info
        print '>> Inserting Data: silver.crm_prd_info'
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

        set @end_time=getdate()
        print 'Query proceesing time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds'
        print('----------------------------------------------------------------')
        print(' ')
        print(' ')
        ----------------------------------------------------------------------
        set @start_time=getdate();
        print '>> Truncating Table: silver.crm_sales_details'
        truncate table silver.crm_sales_details
        print '>> Inserting Data: silver.crm_sales_details'
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
        set @end_time=getdate()
        print 'Query proceesing time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds'
        print('----------------------------------------------------------------')
        print(' ')
        print(' ')
        ----------------------------------------------------------
        print '----------------------Loading ERP tables-----------------------------'
        set @start_time=getdate();
        print '>> Truncating Table: silver.erp_cust_az12'
        truncate table silver.erp_cust_az12
        print '>> Inserting Data: silver.erp_cust_az12'
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

        set @end_time=getdate()
        print 'Query proceesing time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds'
        print('----------------------------------------------------------------')
        print(' ')
        print(' ')
        ---------------------------------------------------------------
        set @start_time=getdate();
        print '>> Truncating Table: silver.erp_loc_a101'
        truncate table silver.erp_loc_a101
        print '>> Inserting Data: silver.erp_loc_a101'
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

        set @end_time=getdate()
        print 'Query proceesing time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds'
        print('----------------------------------------------------------------')
        print(' ')
        print(' ')
        --------------------------------------------------------------------
        set @start_time=getdate();
        print '>> Truncating Table: silver.erp_px_cat_g1v2'
        truncate table silver.erp_px_cat_g1v2
        print '>> Inserting Data: silver.erp_px_cat_g1v2'
        insert into silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
        select id,cat,subcat,maintenance from bronze.erp_px_cat_g1v2
        set @end_time=getdate()
        print 'Query proceesing time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds'
        print('----------------------------------------------------------------')
        print(' ')
        print(' ')
        set @batch_end_time=getdate();
        print 'Loading bronze layer is completed'
        print 'Total load duration '+ cast(datediff(second,@batch_start_time,@batch_end_time) as nvarchar(50))+' Seconds'
    end try
    begin catch
        print '============================================='
        print 'error occured during loading silver layer '
        print 'error messagge' +error_message()
        print 'error number'+ cast(error_number() as nvarchar(50))
        print 'error state' +cast(error_state() as nvarchar(50))
    end catch
end 
