-- Step 1: Create the cleaned table
CREATE TABLE sales_data_cleaned LIKE sales_data_raw;

-- Step 2: Insert cleaned data
INSERT INTO sales_data_cleaned
SELECT
-- Fixing the Order_ID
	CASE
		WHEN Order_ID IS NULL OR Order_ID = ' ' THEN 'Unknown'
		ELSE TRIM(Order_ID)
	END as Order_ID,

    -- Fix Date Format
    CASE
        WHEN Order_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' 	 THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
        WHEN Order_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' 	 THEN STR_TO_DATE(Order_Date, '%d/%m/%Y')
        WHEN Order_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 	 THEN STR_TO_DATE(Order_Date, '%m-%d-%Y')
        WHEN Order_Date REGEXP '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(Order_Date, '%d-%b-%Y')
        ELSE NULL
    END AS order_date,

    -- Standardize Region
    CASE
        WHEN TRIM(LOWER(Region)) = 'north' 		 THEN 'North'
        WHEN TRIM(LOWER(Region)) = 'south' 		 THEN 'South'
        WHEN TRIM(LOWER(Region)) = 'east'  		 THEN 'East'
        WHEN TRIM(LOWER(Region)) = 'west'  		 THEN 'West'
        WHEN Region IS NULL OR TRIM(Region) = '' THEN 'Unknown'
    END AS Region,

    -- Standardize Sales Rep
    CASE
        WHEN Sales_Rep IS NULL OR TRIM(Sales_Rep) = '' THEN 'Unknown'
        ELSE TRIM(REPLACE(REPLACE(REPLACE(
            CONCAT(
                UPPER(SUBSTRING(TRIM(LOWER(Sales_Rep)), 1, 1)),
                SUBSTRING(TRIM(LOWER(Sales_Rep)), 2)),
            ' ', ' '), ' ', ' '), ' ', ' '))
    END AS Sales_Rep,

    -- Standardize Product
    CASE
        WHEN TRIM(LOWER(Product)) = 'laptop'   THEN 'Laptop'
        WHEN TRIM(LOWER(Product)) = 'monitor'  THEN 'Monitor'
        WHEN TRIM(LOWER(Product)) = 'mouse'    THEN 'Mouse'
        WHEN TRIM(LOWER(Product)) = 'keyboard' THEN 'Keyboard'
        WHEN TRIM(LOWER(Product)) = 'headset'  THEN 'Headset'
        WHEN Product IS NULL OR TRIM(LOWER(Product)) = '' THEN 'Unknown'
    END AS Product,

    -- Standardize Channel
    CASE
        WHEN TRIM(LOWER(`Channel`)) = 'retail'     THEN 'Retail'
        WHEN TRIM(LOWER(`Channel`)) = 'direct'     THEN 'Direct'
        WHEN TRIM(LOWER(`Channel`)) = 'online'     THEN 'Online'
        WHEN TRIM(LOWER(`Channel`)) = 'wholesale'  THEN 'Wholesale'
        WHEN `Channel` IS NULL OR TRIM(LOWER(`Channel`)) = '' THEN 'Unknown'
    END AS sales_media,

    -- Fix Quantity & Unit Price
    COALESCE(Quantity, 0) AS quantity,
    COALESCE(ABS(Unit_Price), 0) AS unit_price,

    -- Fix Discount
    CASE
        WHEN `Discount_%` IS NULL   THEN 0
        WHEN `Discount_%` > 1       THEN 0
        WHEN `Discount_%` > 0.50    THEN 0.50
        WHEN `Discount_%` < 0       THEN 0
        ELSE `Discount_%`
    END AS Discount_pct,

    -- Recalculate Revenue
    ROUND(
        COALESCE(ABS(Unit_Price), 0)
        * COALESCE(Quantity, 0)
        * (1 - CASE
                WHEN `Discount_%` IS NULL   THEN 0
                WHEN `Discount_%` > 1       THEN 0
                WHEN `Discount_%` > 0.50    THEN 0.50
                ELSE `Discount_%`
               END)
    ) AS Revenue,

    -- Fix Cost
    COALESCE(ABS(Cost), 0) AS Cost,

    -- Recalculate Profit
    ROUND(
        COALESCE(ABS(Unit_Price), 0)
        * COALESCE(Quantity, 0)
        * (1 - CASE
                WHEN `Discount_%` IS NULL   THEN 0
                WHEN `Discount_%` > 1       THEN 0
                WHEN `Discount_%` > 0.50    THEN 0.50
                ELSE `Discount_%`
               END)
        - COALESCE(ABS(Cost), 0)
    ) AS Profit,

    -- Fix Customer Rating
    CASE
        WHEN Customer_Rating >= 1.0 AND Customer_Rating <= 5.0 THEN Customer_Rating
        ELSE NULL
    END AS Customer_Rating

FROM sales_data_raw;

-- Step 3: View deduplicated results
WITH duplicates AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY Order_ID, Order_Date, Region, Sales_Rep,
                         Product, `Channel`, Quantity, Unit_Price, `Discount_%`,
                         Revenue, Cost, Profit, Customer_Rating
        ) AS ROW_NUM
    FROM sales_data_cleaned
)
SELECT *
FROM duplicates
WHERE ROW_NUM = 1;

-- creating a new table bec we insert CTE's

CREATE TABLE sales_data_final_clean AS SELECT * FROM
    sales_data_raw
WHERE
    1 = 0;

INSERT INTO sales_data_final_clean
SELECT
    case 
		when Order_ID is null or Order_ID = '' then 'Unknown'
        else Order_ID
	end as Ordder_ID,

    -- Reformat Order Date
    DATE_FORMAT(
        CASE 
            WHEN Order_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
            WHEN Order_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}' THEN STR_TO_DATE(Order_Date, '%d/%m/%Y')
            WHEN Order_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}' THEN STR_TO_DATE(Order_Date, '%m-%d-%Y')
            WHEN Order_Date REGEXP '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}' THEN STR_TO_DATE(Order_Date, '%d-%b-%Y')
            ELSE NULL
        END,
    '%Y-%m-%d') AS Order_Date,

    -- Standardize Region
    CASE
        WHEN TRIM(LOWER(Region)) = 'north' THEN 'North'
        WHEN TRIM(LOWER(Region)) = 'south' THEN 'South'
        WHEN TRIM(LOWER(Region)) = 'east'  THEN 'East'
        WHEN TRIM(LOWER(Region)) = 'west'  THEN 'West'
        WHEN Region IS NULL OR TRIM(LOWER(Region)) = '' then 'Unknown'
        ELSE TRIM(Region)
    END AS Region,

    -- Standardize Sales Rep
    CASE
        WHEN Sales_Rep IS NULL OR TRIM(Sales_Rep) = '' THEN 'Unknown'
        ELSE
            CONCAT(
                UPPER(SUBSTRING(
                    TRIM(SUBSTRING_INDEX(TRIM(LOWER(Sales_Rep)),' ',1)),1,1)),
                LOWER(SUBSTRING(
                    TRIM(SUBSTRING_INDEX(TRIM(LOWER(Sales_Rep)),' ',1)),2)),
                ' ',
                UPPER(SUBSTRING(
                    TRIM(SUBSTRING_INDEX(TRIM(LOWER(Sales_Rep)),' ',-1)),1,1)),
                LOWER(SUBSTRING(
                    TRIM(SUBSTRING_INDEX(TRIM(LOWER(Sales_Rep)),' ',-1)),2))
                    )
	end as Sales_Rep,

    -- Standardize Product
    CASE
        WHEN TRIM(LOWER(Product)) = 'laptop'   THEN 'Laptop'
        WHEN TRIM(LOWER(Product)) = 'monitor'  THEN 'Monitor'
        WHEN TRIM(LOWER(Product)) = 'keyboard' THEN 'Keyboard'
        WHEN TRIM(LOWER(Product)) = 'mouse'    THEN 'Mouse'
        WHEN TRIM(LOWER(Product)) = 'headset'  THEN 'Headset'
        WHEN Product IS NULL OR TRIM(LOWER(Product)) ='' then 'Unknown'
        ELSE TRIM(Product)
    END AS Product,

    -- Standardize Channel
    CASE
        WHEN TRIM(LOWER(`Channel`)) = 'online'     THEN 'Online'
        WHEN TRIM(LOWER(`Channel`)) = 'retail'     THEN 'Retail'
        WHEN TRIM(LOWER(`Channel`)) = 'wholesale'  THEN 'Wholesale'
        WHEN TRIM(LOWER(`Channel`)) = 'direct'     THEN 'Direct'
        WHEN `Channel` IS NULL or   trim(lower(`Channel`))= ''THEN 'Unknown'
        ELSE TRIM(`Channel`)
    END AS Channel,

    -- Fix Quantity
    COALESCE(Quantity, 0) AS Quantity,

    -- Fix Unit Price
    COALESCE(ABS(Unit_Price), 0) AS Unit_Price,

    -- Fix Discount
    CASE
        WHEN `Discount_%` IS NULL or `Discount_%` = ''  THEN 0
        WHEN `Discount_%` > 1       THEN 0
        WHEN `Discount_%` > 0.50    THEN 0.50
        WHEN `Discount_%` < 0       THEN 0
        ELSE `Discount_%`
    END AS `Discount_%`,

    -- Recalculate Revenue
    ROUND(
        COALESCE(ABS(Unit_Price), 0)
        * COALESCE(Quantity, 0)
        * (1 - CASE
                WHEN `Discount_%` IS NULL OR `Discount_%` > 1 THEN 0
                WHEN `Discount_%` > 0.50 THEN 0.50
                ELSE `Discount_%`
               END),
    2) AS Revenue,

    -- Fix Cost
    COALESCE(Cost, 0) AS Cost,

    -- Recalculate Profit
    ROUND(
        COALESCE(ABS(Unit_Price), 0)
        * COALESCE(Quantity, 0)
        * (1 - CASE
                WHEN `Discount_%` IS NULL OR `Discount_%` > 1 THEN 0
                WHEN `Discount_%` > 0.50 THEN 0.50
                ELSE `Discount_%`
               END)
        - COALESCE(Cost, 0),
    2) AS Profit,

    -- Fix Customer Rating
    CASE 
        WHEN Customer_Rating >= 1.0 and Customer_Rating <= 5.0
			then Customer_Rating
        ELSE NULL
    END AS Customer_Rating

FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY Order_ID, Order_Date, Region, Sales_Rep,
										Product, Channel, Quantity, Unit_Price
										ORDER BY Order_ID) AS Row_Num
    FROM sales_data_raw
) AS Deduplicated
WHERE Row_Num = 1;

SELECT 
    *
FROM
    sales_data_final_clean;
    
-- adding a KPI column
ALTER TABLE sales_data_final_clean
ADD COLUMN order_status VARCHAR(10);

UPDATE sales_data_final_clean 
SET 
    order_status = CASE
        WHEN Profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END;

-- checking the diffrence between raw and cleaned one

SELECT 'raw'   AS source, COUNT(*) AS total_rows FROM sales_data_raw
UNION ALL
SELECT 'clean' AS source, COUNT(*) AS total_rows FROM sales_data_final_clean;
 
-- Null counts in clean table
SELECT
    SUM(CASE WHEN Order_ID        IS NULL THEN 1 ELSE 0 END) 		AS null_order_id,
    SUM(CASE WHEN Order_Date      IS NULL THEN 1 ELSE 0 END) 		AS null_order_date,
    SUM(CASE WHEN Region          = 'Unknown' THEN 1 ELSE 0 END) 	AS unknown_region,
    SUM(CASE WHEN Sales_Rep       = 'Unknown' THEN 1 ELSE 0 END) 	AS unknown_sales_rep,
    SUM(CASE WHEN Product         = 'Unknown' THEN 1 ELSE 0 END) 	AS unknown_product,
    SUM(CASE WHEN Customer_Rating IS NULL THEN 1 ELSE 0 END) 		AS null_rating
FROM sales_data_final_clean;
 
-- Check no invalid discounts remain
SELECT COUNT(*) AS invalid_discounts
FROM sales_data_final_clean
WHERE `Discount_%` > 1 OR `Discount_%` < 0;
 
-- Check no negative prices remain
SELECT COUNT(*) AS negative_prices
FROM sales_data_final_clean
WHERE Unit_Price < 0;
