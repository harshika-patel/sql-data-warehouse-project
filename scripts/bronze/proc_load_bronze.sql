/*bulk insert::
txt,csv--bulk insert--->in database */
create or alter procedure bronze.load_bronze as 
begin
      declare @start_time datetime, @end_time datetime,@batch_start_time datetime,@batch_end_time datetime
      begin try
      set @batch_start_time=getdate()
        print('============================')
        print'Loading Bronze Layer'
        print('============================')
        print('----------------------------')
        print('Loading CRM Tables')
        print('----------------------------')
        --------------------------------------------------------------------
        set @start_time=getdate();

        print('>> Truncating Table: bronze.crm_cust_info')
        TRUNCATE TABLE bronze.crm_cust_info;

        print('>> Inserting Table: bronze.crm_cust_info')
        bulk insert bronze.crm_cust_info
        from 'C:\Users\dhava\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        with (
          firstrow=2,
          fieldterminator=',',
          tablock
        )
        set @end_time=getdate();
        print 'Query running time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds'

       --------------------------------------------------------

        set @start_time=getdate();
        print('>> Truncating Table: bronze.crm_prd_info')
        TRUNCATE TABLE bronze.crm_prd_info;

        print('>> Inserting Table: bronze.crm_prd_info')
        bulk insert bronze.crm_prd_info
        from 'C:\Users\dhava\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        with (
          firstrow=2,
          fieldterminator=',',
          tablock
        )
        set @end_time=getdate();
        print('Query running time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds')
       --------------------------------------------------------

        set @start_time=getdate();
        print('>> Truncating Table: bronze.crm_sales_details')
       
        TRUNCATE TABLE bronze.crm_sales_details;

        print('>> Inserting Table: bronze.crm_sales_details')
        bulk insert bronze.crm_sales_details
        from 'C:\Users\dhava\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        with (
          firstrow=2,
          fieldterminator=',',
          tablock
        )
        set @end_time=getdate();
        print('Query running time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds')

       ------------------------------------------------------------------------------------

      
        print('----------------------------')
        print('Loading ERP Tables')
        print('----------------------------')
        set @start_time=getdate();
        print('>> Truncating Table: bronze.erp_cust_az12')
        print('>> Inserting Table: bronze.erp_cust_az12')
        TRUNCATE TABLE bronze.erp_cust_az12;
        bulk insert bronze.erp_cust_az12
        from 'C:\Users\dhava\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
        with (
          firstrow=2,
          fieldterminator=',',
          tablock
        )
        set @end_time=getdate();
        print('Query running time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds')
        -------------------------------------------------------------
    
        set @start_time=getdate();
        print('>> Truncating Table: bronze.erp_loc_a101')
        print('>> Inserting Table: bronze.erp_loc_a101')
        TRUNCATE TABLE bronze.erp_loc_a101;
        bulk insert bronze.erp_loc_a101
        from 'C:\Users\dhava\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
        with (
          firstrow=2,
          fieldterminator=',',
          tablock
        )
        set @end_time=getdate();
        print('Query running time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds')
        
    ----------------------------------------------------------------------
        set @start_time=getdate();
        print('>> Truncating Table:bronze.erp_px_cat_g1v2')
        print('>> inserting Table:bronze.erp_px_cat_g1v2')
        TRUNCATE TABLE bronze.erp_px_cat_g1v2
        bulk insert bronze.erp_px_cat_g1v2
        from 'C:\Users\dhava\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
        with (
          firstrow=2,
          fieldterminator=',',
          tablock
        )
        set @end_time=getdate();
        print('Query running time is '+ cast(datediff(second,@start_time,@end_time) as nvarchar(50))+' Seconds')
        -----------------------------------------------------------------------------

        set @batch_end_time=getdate();
        print 'Loading bronze layer is completed'
        print 'Total load duration '+ cast(datediff(second,@batch_start_time,@batch_end_time) as nvarchar(50))+' Seconds'
     end try
     begin catch
            print '========================================'
            print'error occured during loading bronze layer'
            print 'error messge'+ error_message();
            print 'error Number'+ cast(error_number() as nvarchar(50));
            print 'Error State'+ cast(error_state() as nvarchar(50));
            print '========================================'
           
     end catch;
     
end;

exec bronze.load_bronze
