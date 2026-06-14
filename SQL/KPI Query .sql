-- calcualting KPI's
#----------------------------------------total summary-----------------------------------------------------#
SELECT 
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(revenue), 2) AS total_revenue,
    COUNT(*) AS total_orders,
    ROUND(SUM(revenue) / COUNT(Order_ID), 2) AS avg_order_value,
    ROUND(SUM(profit) / SUM(revenue) * 100, 2) AS profit_margin_pct
FROM
    sales_data_final_clean;
#-------------------------------------loss breakdown by region----------------------------------------------#
SELECT 
    Region,
    COUNT(*) total_orders,
    ROUND(SUM(profit), 2) total_profit,
    ROUND(SUM(Revenue),2) total_revenue,
    ROUND(((SUM(Revenue)-sum(Cost))/sum(revenue)) *100 ,2) as profit_margin_pct,
    ROUND(SUM(case when order_status = 'Loss' then 1 else 0 end) * 100 / count(*),2) as loss_pct,
	ROUND(avg(`Discount_%`)* 100,2) as avg_discount_pct
FROM
    sales_data_final_clean
GROUP BY region
ORDER BY total_profit DESC;
#--------------------------------------loss breakdown by product---------------------------------------------#

SELECT 
    Product,
    COUNT(*) as total_orders,
    ROUND(SUM(profit), 2) total_profit,
    ROUND(SUM(REvenue),2) total_revenue,
    ROUND(((SUM(Revenue)-sum(Cost))/sum(revenue)) *100 ,2) as profit_margin_pct,
    ROUND(SUM(case when order_status = 'Loss' then 1 else 0 end) * 100 / count(*),2) as loss_pct,
	ROUND(avg(`Discount_%`) * 100,2) as avg_discount_pct
FROM
    sales_data_final_clean
GROUP BY product
ORDER BY total_profit DESC;

#---------------------------------------Loss breakdown by channel----------------------------------------------#

SELECT 
    `Channel`,
    COUNT(*) total_orders,
    ROUND(SUM(profit), 2) total_profit,
    ROUND(SUM(REvenue),2) total_revenue,
    ROUND(((SUM(Revenue)-sum(Cost))/sum(revenue)) *100 ,2) as profit_margin_pct,
    ROUND(SUM(case when order_status = 'Loss' then 1 else 0 end) * 100 / count(*),2) as loss_pct,
	ROUND(avg(`Discount_%`) * 100,2) as avg_discount_pct
FROM
    sales_data_final_clean
GROUP BY `Channel`
ORDER BY total_profit DESC;

#------------------------------------ sales representitive performance------------------------------------------#

SELECT 
    Sales_Rep,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'loss' THEN 1 ELSE 0 END) AS loss_order,
    ROUND(
		SUM(CASE WHEN order_status = 'loss' THEN 1 ELSE 0 END) * 100 / COUNT(*),
		2) AS loss_rate_pct
FROM
    sales_data_final_clean
GROUP BY Sales_Rep
ORDER BY loss_rate_pct DESC;

#--------------------------------average discount rate per sales_rep--------------------------------------------#

SELECT 
    Sales_Rep,
    ROUND(AVG(`Discount_%`) * 100, 2) AS avg_discount_pct,
    ROUND(AVG(Profit), 2) AS avg_profit,
    ROUND(AVG(Customer_Rating), 2) AS avg_customer_rating
FROM
    sales_data_final_clean
GROUP BY Sales_Rep
ORDER BY avg_discount_pct DESC;

# --------------------------------------full sales rep performance---------------------------------------------- #

SELECT
	Sales_Rep,
    COUNT(*) as total_orders,
    ROUND(SUM(Revenue),2) as total_revenue,
    round(sum(Profit),2) as total_profit,
	ROUND(AVG(`Discount_%`),2) as  avg_Discount_pct,
    ROUND(SUM(case when order_status = 'loss' then 1 else 0 end),2) as loss_orders,
    ROUND(SUM(case when ORder_status = 'loss' then 1 else 0 end) *100 / COUNT(*) ,2) as loss_order_pct,
    Round(AVG(Customer_Rating),2) as avg_customer_rating
FROM sales_data_final_clean
GROUP BY Sales_Rep
ORDER BY loss_order_pct desc;

#------------------------------------------the monthly trend --------------------------------------------------#

select 
	YEAR(Order_Date) as order_year,
	MONTH(Order_Date) as order_month,
	COUNT(*) as total_orders,
	ROUND(SUM(Revenue),2) as total_revenue,
	round(sum(Profit),2) as total_profit,
    ROUND(((SUM(revenue) - SUM(Cost)) / SUM(Revenue)) * 100,2) as profit_margin_pct
FROM sales_data_final_clean
GROUP BY order_year , order_month
ORDER BY order_year, order_month;

#---------------------------------------Discount analysis (bucket)---------------------------------------------#

SELECT 
    CASE 
        WHEN `Discount_%` = 0 THEN '1. No Discount'
        WHEN `Discount_%` <= 0.10 THEN '2. Low (1-10%)'
        WHEN `Discount_%` <= 0.20 THEN '3. Medium (11-20%)'
        WHEN `Discount_%` <= 0.30 THEN '4. High (21-30%)'
        ELSE '5. Very High (31-45%)'
    END AS discount_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(Profit), 2) AS avg_profit,
    ROUND(AVG(Revenue), 2) AS avg_revenue,
    ROUND((SUM(Revenue) - SUM(Cost)) / SUM(Revenue) * 100, 2) AS profit_margin_pct,
    SUM(CASE WHEN order_status = 'Loss' THEN 1 ELSE 0 END) AS loss_orders
FROM sales_data_final_clean
GROUP BY discount_bucket
ORDER BY discount_bucket;

#-----------------------------------------------loss breakdown-------------------------------------------------#

select 
	Region,
    Product,
    Sales_Rep,
    count(8) as total_orders,
    SUM( CASE WHEN order_status = 'Loss' THEN 1 ELSE 0 end) as loss_orders,
    ROUND((SUM( CASE WHEN order_status = 'Loss' THEN 1 ELSE 0 end) * 100) /COUNT(*) ,2) as loss_rate_pct,
    ROUND(AVG(`Discount_%`)* 100,2) as avg_discount_pct
from sales_data_final_clean
GROUP BY Region,Product,Sales_Rep
HAVING COUNT(*) >= 5
ORDER BY loss_rate_pct desc
LIMIT 10;