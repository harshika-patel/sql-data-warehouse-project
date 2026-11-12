/*
===============================================================
Create Database and Schemas
===============================================================
Script Purpose:
    This scripts Creates a New database named 'DataWarehouse' After checking if it already exists.
    if the databases exists, it is dropped and recreated. Additionally, the script sets up three schemas within
    the database:'bronze','silver','gold'
Warning:
    Running this script will drop the entire datawarehouse database if it exists.
    All data in the database will be permanently deleted. Proceed with caution and ensure you have proper 
    backups before running this script.
 */
use master
go
if exists(select 1 from sys.databases where name='Datawarehouse')
begin
    alter database Datawarehouse set single_user with rollback immediate
    drop database Datawarehouse
end
go
--here we create the Datawarehouse database
create database Datawarehouse
go
use Datawarehouse;
go
--create some schemas
create schema bronze;
go
create schema silver;
go--when we run mutiple query together we need to used go so we can run togther
create schema gold;
go
--project Intailization
---Now commit code in git Repo

