# sql-data-warehouse-project
Building a modern Data Warehouse with SQL server, Including ETL Process, Data modeling and analytics.
Notion LInk:
https://app.notion.com/p/DataBase-WareHouse-Project-4167932acbce80adb532ce60de6df331?source=copy_link
SQL Server Data Warehouse | Medallion Architecture
An end-to-end SQL Server data warehousing portfolio project that integrates CRM and ERP sales data, transforms raw CSV extracts into clean datasets, and creates a dimensional model for reporting and exploratory data analysis (EDA).
Project overview
Goal: Create a centralized, business-ready view of customers, products, and sales by combining data from two source systems.

The project follows the Medallion Architecture:
CRM CSV files ─┐
               ├──> Bronze (raw SQL tables) ──> Silver (clean SQL tables)
ERP CSV files ─┘                                    │
                                                   ▼
                                       Gold (star-schema SQL views)
                                                   │
                                                   ▼
                                          SQL EDA / reporting
Scope: This implementation uses full refreshes (TRUNCATE + load) for Bronze and Silver. It is designed for a latest-state analytical dataset, not incremental ingestion or historical tracking.

Technology and concepts
- Database: Microsoft SQL Server; T-SQL
- Ingestion: BULK INSERT from CRM and ERP CSV files
- Transformations: SQL stored procedures, joins, CASE, TRIM, REPLACE, ISNULL, date conversion and window functions (DENSE_RANK, LEAD, ROW_NUMBER)
- Modeling: Star schema, fact and dimension views, surrogate keys
- Quality checks: Duplicate and null detection, referential integrity, date validation and sales business rules
- Development: Architecture planning in draw.io and version control with Git/GitHub
Data sources
System	Source CSV	Bronze / Silver table	Purpose
CRM	cust_info.csv	crm_cust_info	Customer identity and profile
CRM	prd_info.csv	crm_prd_info	Product details and lifecycle dates
CRM	sales_details.csv	crm_sales_details	Orders, dates, quantities, prices and sales
ERP	cust_az12.csv	erp_cust_az12	Customer birthdates and gender
ERP	loc_a101.csv	erp_loc_a101	Customer country
ERP	px_cat_g1v2.csv	erp_px_cat_g1v2	Product category and subcategory


The same six source datasets are represented as SQL tables in both the bronze and silver schemas.
Data architecture
1. Bronze — raw ingestion
The bronze schema preserves the incoming source structure without business transformations. The bronze.load_bronze stored procedure loads all six CSVs using BULK INSERT, with full-refresh table truncation, elapsed-time logging and TRY...CATCH error messages.
2. Silver — cleaning and standardization
The silver schema holds standardized SQL tables. The silver.load_silver procedure applies transformations such as:
- Trimming customer names and standardizing gender and marital-status values.
- Filtering null customer IDs and retaining the most recent records based on customer creation date.
- Splitting product keys into category and product identifiers; mapping product-line codes to descriptive labels.
- Replacing missing product costs with zero and deriving product end dates using LEAD().
- Converting integer-formatted sales dates into SQL DATE values.
- Checking sales against sales amount = quantity × unit price and applying correction logic for invalid amounts or prices.
- Standardizing customer IDs, country names and ERP gender values.
- Adding a dwh_create_date load timestamp to Silver tables.
3. Gold — business-ready dimensional model
The gold schema exposes three reporting views:
View	Type	Description
gold.dim_customers	Dimension	Combines CRM customer profiles with ERP demographics and countries
gold.dim_products	Dimension	Combines product details with ERP categories; filters to products without an end date
gold.fact_sales	Fact	Sales orders with dates, sales amount, quantity, price and dimension keys


Star schema:
   gold.dim_customers          gold.dim_products
   ------------------          -----------------
   customer_key (PK*)          product_key (PK*)
   customer_id                 product_id
   customer_number             product_number
   first_name, last_name       product_name
   country, gender             category, subcategory
          |                            |
          | customer_key               | product_key
          +------------+---------------+
                       |
                gold.fact_sales
                ---------------
                order_number
                customer_key
                product_key
                order_date
                shipping_date
                due_date
                sales_amount
                quantity
                price
* Surrogate keys are generated in the dimension views with ROW_NUMBER(); they are not declared primary-key constraints on the views.
Data quality validation
SQL checks are performed before and after transformations, including:
- Duplicate or missing customer/product identifiers.
- Leading or trailing whitespace and inconsistent categorical values.
- Null, negative or invalid product costs, prices and quantities.
- Invalid dates and chronological inconsistencies between order, shipping and due dates.
- Missing customer or product references in sales data.
- Duplicate dimension keys and unmatched sales fact keys.
Example:
-- Check for duplicate or missing customer IDs
SELECT customer_id, COUNT(*) AS record_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1 OR customer_id IS NULL;

-- Check sales records with unmatched product dimension keys
SELECT *
FROM gold.fact_sales
WHERE product_key IS NULL;
Exploratory Data Analysis (EDA)
The project introduces EDA using the Gold layer, including data profiling, basic SQL queries, aggregations and subqueries. Examples of business questions to explore next:
- What is the total sales amount and order volume?
- Which products and categories generate the most sales?
- How does revenue vary by country?
- How do monthly sales trends change over time?
- Which customers contribute the most revenue?
Example query:
SELECT
    p.category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.quantity) AS units_sold
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_sales DESC;
The supplied project notes document the warehouse build and the beginning of EDA; they do not establish completed EDA results or business findings.

How to run
1. Install or access Microsoft SQL Server and a SQL client such as SQL Server Management Studio (SSMS).
2. Place the six CSV source files in accessible source_crm and source_erp directories.
3. Run the database initialization SQL to create Datawarehouse and the bronze, silver and gold schemas.
4. Create the six Bronze tables and update the absolute CSV paths in bronze.load_bronze for your own environment.
5. Run EXEC bronze.load_bronze; and validate the raw loads.
6. Create the Silver tables and the silver.load_silver procedure, then run EXEC silver.load_silver;.
7. Run the data-quality checks and create gold.dim_customers, gold.dim_products and gold.fact_sales in that order.
8. Query the Gold views to perform EDA or connect a reporting tool.
Important: The database initialization script in the project notes drops and recreates the Datawarehouse database if it already exists. Do not run it against a database containing data you need to keep. CSV paths in the example ingestion script are machine-specific and must be changed.
Repository organization (suggested)
sql-data-warehouse-project/
├── datasets/
│   ├── source_crm/
│   └── source_erp/
├── scripts/
│   ├── init_database.sql
│   ├── bronze/
│   ├── silver/
│   └── gold/
├── tests/
├── docs/
│   └── architecture.png
└── README.md
This is a recommended layout, not a verified listing of the current repository. Place your existing SQL scripts and draw.io architecture export into the corresponding folders.
Project highlights
- Integrated six CRM/ERP CSV datasets into a three-layer SQL Server warehouse.
- Created reusable Bronze and Silver loading procedures with execution-time and error logging.
- Applied data cleaning, standardization, enrichment and SQL window functions.
- Designed a three-view star schema for customer, product and sales analytics.
- Wrote SQL checks for data quality and prepared the Gold layer for business reporting.
Future improvements
- Expand EDA into documented sales and customer insights.
- Add automated data-quality tests and reconciliation counts.
- Add scheduling, monitoring and more robust error handling.
- Explore incremental loads and stable persisted surrogate keys for production scenarios.
- Optionally build a Power BI report using the Gold views.
Author
Harshika Patel
Data Analytics / SQL / Business Intelligence Portfolio Project
