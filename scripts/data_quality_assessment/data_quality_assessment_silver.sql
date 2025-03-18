----------------------------------------
	--Silver Layer
----------------------------------------

----------------------------------------
	--Table silver.crm_cust_info
----------------------------------------

-- Check Duplicates and Nulls in Primary Key
-- Expectation: No Result
SELECT cst_id, COUNT(*) -- check duplicate primary keys
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

-- Check for Unwanted Space in String Values
-- Expectation: No Result
SELECT cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key)

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) -- If original value is not equal to the same value after trimming, means there are spaces

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- Data Standardization & Consistency
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

SELECT * FROM silver.crm_cust_info

----------------------------------------
	--Table silver.crm_prd_info
----------------------------------------

-- Check Duplicates and Nulls in Primary Key
-- Expectation: No Result
SELECT prd_id, COUNT(*) -- check duplicate primary keys
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Check for Unwanted Space in String Values
-- Expectation: No Result
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for NULLs or Negative Numbers
-- Expectation: No Result
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Check for Invalid Date Orders
-- Expectation: No Result
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

----------------------------------------
	--Table silver.crm_sales_details
----------------------------------------

-- Check for Invalid Date Order
-- Expectation: No Result
SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

-- Check Data Consistency: Between Sales, Quantity, and Price
-- Expectation: No Result
SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

SELECT * FROM silver.crm_sales_details

----------------------------------------
	--Table silver.erp_cust_az12
----------------------------------------

-- Identify Out-of-Range Dates
SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT gen
FROM silver.erp_cust_az12

SELECT * FROM silver.erp_cust_az12

----------------------------------------
	--Table silver.erp_loc_a101
----------------------------------------

-- Data Standardization & Consistency
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry

----------------------------------------
	--Table silver.erp_px_cat_g1v2
----------------------------------------

-- Check for Unwanted Space in String Values
-- Expectation: No Result
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- Data Standardization & Consistency
SELECT DISTINCT
cat
FROM silver.erp_px_cat_g1v2

SELECT DISTINCT
subcat
FROM silver.erp_px_cat_g1v2

SELECT DISTINCT
maintenance
FROM silver.erp_px_cat_g1v2

SELECT * FROM silver.erp_px_cat_g1v2
