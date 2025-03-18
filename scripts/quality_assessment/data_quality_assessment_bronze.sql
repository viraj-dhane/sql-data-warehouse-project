----------------------------------------
	--Bronze Layer
----------------------------------------

----------------------------------------
	--Table bronze.crm_cust_info
----------------------------------------
SELECT * FROM bronze.crm_cust_info;

-- Check Duplicates and Nulls in Primary Key
-- Expectation: No Result
SELECT cst_id, COUNT(*) -- check duplicate primary keys
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

SELECT 
*
FROM (
		SELECT
		*,
		ROW_NUMBER () OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
		FROM bronze.crm_cust_info
		WHERE cst_id IS NOT NULL
)t WHERE flag_last = 1

-- Check for Unwanted Space in String Values
-- Expectation: No Result
SELECT cst_key
FROM bronze.crm_cust_info
WHERE cst_key != TRIM(cst_key)

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) -- If original value is not equal to the same value after trimming, means there are spaces

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- Data Standardization & Consistency
SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info

SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

----------------------------------------
----------------------------------------

----------------------------------------
	--Table bronze.crm_prd_info
----------------------------------------
SELECT * FROM bronze.crm_prd_info

-- Check Duplicates and Nulls in Primary Key
-- Expectation: No Result
SELECT prd_id, COUNT(*) -- check duplicate primary keys
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Check for Unwanted Space in String Values
-- Expectation: No Result
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for NULLs or Negative Numbers
-- Expectation: No Result
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

-- Check for Invalid Date Orders
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt

SELECT
	prd_id,
	prd_key,
	prd_nm,
	prd_start_dt,
	prd_end_dt,
	DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_date -- LEAD() - Access values from the next row within a window
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509')

----------------------------------------
----------------------------------------

----------------------------------------
	--Table bronze.crm_sales_details
----------------------------------------
SELECT * FROM bronze.crm_sales_details

SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
-- WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)
-- WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)

-- Check for Unwanted Space in String Values
-- Expectation: No Result
SELECT sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)

-- Check for Invalid Dates
-- Expectation: No Result
SELECT 
NULLIF(sls_order_dt, 0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0
OR LEN(sls_order_dt) !=8
OR sls_order_dt > 20500101 OR sls_order_dt < 19000101 -- To check outliers

SELECT 
NULLIF(sls_ship_dt, 0) sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0
OR LEN(sls_ship_dt) !=8
OR sls_ship_dt > 20500101 OR sls_ship_dt < 19000101 -- To check outliers

SELECT 
NULLIF(sls_due_dt, 0) sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
OR LEN(sls_due_dt) !=8
OR sls_due_dt > 20500101 OR sls_due_dt < 19000101 -- To check outliers

SELECT
*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt -- Check for Invalid Date Order

-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.
SELECT DISTINCT
	sls_sales AS old_sls_sales,
	sls_quantity AS old_sls_quantity,
	sls_price AS old_sls_price,
	CASE 
		WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
				THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales,
	sls_quantity,
	CASE 
		WHEN sls_price IS NULL OR sls_price <= 0 
				THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price  -- Derive price if original value is invalid
	END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

----------------------------------------
----------------------------------------

----------------------------------------
	--Table bronze.erp_cust_az12
----------------------------------------
SELECT * FROM bronze.erp_cust_az12

-- Check for Additional Characters in Customer Id
-- Expectation: No Result
SELECT
cid,
CASE 
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END  AS cid,
bdate,
gen
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END NOT IN (SELECT DISTINCT cst_key	FROM silver.crm_cust_info)

-- Identify Out-of-Range Dates
SELECT DISTINCT
bdate,
CASE
	WHEN bdate > GETDATE() THEN NULL
	ELSE bdate
END AS bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT gen
FROM bronze.erp_cust_az12

----------------------------------------
----------------------------------------

----------------------------------------
	--Table bronze.erp_loc_a101
----------------------------------------
SELECT * FROM bronze.erp_loc_a101

SELECT
REPLACE(cid, '-', '') cid,
cntry
FROM bronze.erp_loc_a101 WHERE REPLACE(cid, '-', '') NOT IN
(SELECT cst_key FROM silver.crm_cust_info)

-- Data Standardization & Consistency
SELECT DISTINCT
cntry,
CASE
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS cntry -- Normalize and Handle missing or blank country codes
FROM bronze.erp_loc_a101

----------------------------------------
----------------------------------------

----------------------------------------
	--Table bronze.erp_px_cat_g1v2
----------------------------------------
SELECT * FROM bronze.erp_px_cat_g1v2

-- Check for Unwanted Space in String Values
-- Expectation: No Result
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- Data Standardization & Consistency
SELECT DISTINCT
cat
FROM bronze.erp_px_cat_g1v2

SELECT DISTINCT
subcat
FROM bronze.erp_px_cat_g1v2

SELECT DISTINCT
maintenance
FROM bronze.erp_px_cat_g1v2
