-- Easy:

-- Basic Aggregation Queries:
-- Question 1: Write SQL queries to compute the total number of items bought (boughtInLastMonth) for each product category.

# Finding total number of items bought for each product category
select amazon_categories.category_name as Category, 
		sum(amazon_products.boughtInLastMonth) as TotalItemsBought
from amazon_products
join amazon_categories
on amazon_categories.id = amazon_products.category_id
group by (amazon_categories.category_name)
order by TotalItemsBought asc;

-- Average Price by Category:
-- Question 2: Calculate the average price of products in each category using SQL.

# Calculating the average price of products in each category 
select amazon_categories.category_name as Category, 
		avg(amazon_products.price) as AveragePrice
from amazon_products
join amazon_categories
on amazon_categories.id = amazon_products.category_id
group by (amazon_categories.category_name)
order by AveragePrice asc;



-- Product Count by Category:
-- Question 3: Determine how many products exist in each category.
# Finding total number of entries for each product
select amazon_categories.category_name as Category, 
		count(*) as TotalProducts
from amazon_products
join amazon_categories
on amazon_categories.id = amazon_products.category_id
group by (amazon_categories.category_name)
order by TotalProducts asc;


-- Medium:

-- Sales Performance Comparison:
-- Question 1: Compare the sales performance of products marked as isBestSeller versus non-bestselling products across different categories.
# Creating index for better optimization

# Identifying sales performance for both product type (isBestSeller or isNonBestSeller)
CREATE INDEX idx_category_id_isBestSeller ON amazon_products (category_id, isBestSeller, price, listPrice, boughtInLastMonth);

# CTE to aggregate sales performance of products
with sales_all_products as (
		select amazon_products.category_id as Category_ID,
				amazon_categories.category_name as Category_Name,
                amazon_products.isBestSeller as BestSeller,
				sum(amazon_products.boughtInLastMonth) as total_sold,
                avg(amazon_products.price) as avg_price,
                avg(amazon_products.stars) as avg_ratings,
                avg(amazon_products.listPrice - amazon_products.price) as avg_profit_margin
		from amazon_products
		join amazon_categories
		on
		amazon_categories.id = amazon_products.category_id
		group by category_id, amazon_categories.category_name, amazon_products.isBestSeller
		order by category_id asc
),

# CTE for best selling products
best_selling as (
		select Category_ID,
				Category_Name,
                BestSeller,
                total_sold,
                avg_price,
                avg_ratings,
                avg_profit_margin
        from sales_all_products
        where BestSeller = true
),

# CTE for non best selling products
non_best_selling as (
		select Category_ID,
				Category_Name,
                BestSeller,
                total_sold,
                avg_price,
                avg_ratings,
                avg_profit_margin
        from sales_all_products
        where BestSeller = false
)

# Combining results for comparison
select  "Best Selling" as Category_Type,
		Category_ID,
		Category_Name,
		BestSeller,
		total_sold,
		avg_price,
		avg_ratings,
		avg_profit_margin
from best_selling

union all

select "Not Best Selling" as Category_Type,
		Category_ID,
		Category_Name,
		BestSeller,
		total_sold,
		avg_price,
		avg_ratings,
		avg_profit_margin
from non_best_selling;


-- Top and Bottom Performers:
-- Question 2: Identify the top 10 and bottom 10 products based on boughtInLastMonth and compare their attributes.

# Using CTE
# Calculating stats for all products in each product category
with all_products as (
select amazon_products.category_id,
		amazon_categories.category_name,
        avg(stars) as AvgRatings,
        avg(price) as AvgPrice,
        avg(listPrice) as AvgListPrice,
		sum(boughtInLastMonth) as TotalboughtInLastMonth
        
from amazon_products
join amazon_categories
on amazon_categories.id = amazon_products.category_id
group by amazon_products.category_id, amazon_categories.category_name
order by TotalboughtInLastMonth asc
),

# Based on stats finding top 10 best products based on total quantity sold in last month
top10_products as (
		select category_id,
				category_name,
                TotalboughtInLastMonth
        from all_products
        order by TotalboughtInLastMonth desc
        limit 10
),

# Based on stats finding bottom 10 best products based on total quantity sold in last month
bottom10_products as (
		select category_id,
				category_name,
                TotalboughtInLastMonth
        from all_products
        order by TotalboughtInLastMonth asc
        limit 10
),

# Comparing both(top 10 and bottom 10) based on quantity sold and other stats
comparison as (
		select p.category_id,
				p.category_name,
                p.AvgRatings,
                p.AvgPrice,
                p.AvgListPrice,
                p.TotalboughtInLastMonth,
                case 
					when tp.category_id is not null then "Top 10"
                    when bp.category_id is not null then "Bottom 10"
                    else "Middle"
				end as "CategoryType"
        from all_products p
		left join top10_products tp
        on tp.category_id = p.category_id
        left join bottom10_products bp
        on bp.category_id = p.category_id
)

# Final Step, retieving data based on previous analysis
select *
from compare
where CategoryType in ("Top 10", "Bottom 10")
order by CategoryType, TotalboughtInLastMonth desc;


-- Category Insights with Joins:
-- Question 3: Join the products dataset with the categories dataset to analyze sales metrics by category, such as average boughtInLastMonth and price range.

select amazon_categories.id as Category_ID,
		amazon_categories.category_name as Category_Name,
        avg(amazon_products.price) as AvgPriceRange,
        avg(amazon_products.listPrice) as AvgListPriceRange,
        avg(amazon_products.stars) as AvgRatingStars,
        avg(amazon_products.listPrice - amazon_products.price) as AvgProfitMargin
from amazon_products
join 
amazon_categories
on 
amazon_categories.id = amazon_products.category_id
group by amazon_categories.id, amazon_categories.category_name
order by Category_ID asc;


-- Advanced:

-- Complex Sales Analysis:
-- Question 1: Write complex SQL queries to analyze sales performance based on multiple attributes like price, ratings, and bestseller status, and provide a comprehensive report.

# aggregating sales data by product attributes like price, ratings, and bestseller_status, etc.
with sales_summary as (
    select ap.category_id,
			a.category_name,			
			ap.price,
            ap.stars as ratings,
            ap.isBestSeller as bestseller_status,
            sum(ap.boughtInLastMonth) as total_sold,
            avg(ap.price) as avgprice,
            avg(ap.stars) as avgratings
    from amazon_products ap
    join amazon_categories a
    on a.id = ap.category_id
    group by ap.category_id, a.category_name, ap.price, ap.stars, ap.isBestSeller
),

# Analyzing performance based on different price ranges:
price_analysis as (
		select 
			case
				when price < 50 then "Under 50"
                when price between 50 and 100 then "50 - 100"
                when price between 100 and 200 then "100 - 200"
                else "More than 200"
			end as Price_Range,
             count(category_id) as num_products,
                sum(total_sold) as total_sold,
                avg(avgprice) as avg_price,
                avg(avgratings) as avg_ratings
        from sales_summary
        group by Price_Range
),

# Evaluating that how products with different ratings perform
rating_analysis as (
		select 
			case
				when ratings < 2 then "1 star"
                when ratings between 2 and 4 then "2 - 4 stars"
                else "5 stars"
			end as rating_range,
            count(category_id) as num_products,
            sum(total_sold) as total_sold,
            avg(avgprice) as avg_price,
            avg(ratings) as avg_ratings
        from sales_summary
        group by rating_range
),

# Comparing performance between bestsellers and non-bestsellers:
bestseller_analysis as (
		select 
				bestseller_status,
                count(category_id) as num_products,
                sum(total_sold) as total_sold,
                avg(avgprice) as avg_price,
                avg(avgratings) as avg_ratings
			from sales_summary
            group by bestseller_status
)

# Combining all the analyses into a comprehensive report
select
    'Price Range Analysis' as report_type,
    price_range as attribute,
    num_products,
    total_sold,
    avg_price,
    avg_ratings
from price_analysis
union all
select
    'Ratings Analysis' as report_type,
    rating_range as attribute,
    num_products,
    total_sold,
    avg_price,
    avg_ratings
from rating_analysis
union all
select
    'Bestseller Status Analysis' as report_type,
    bestseller_status as attribute,
    num_products,
    total_sold,
    avg_price,
    avg_ratings
from bestseller_analysis
order by report_type, attribute;



-- Subquery Analysis:
-- Question 2:  compare sales performance between categories with the highest and lowest average prices.

# Using CTE
# Identifying Categories with Highest and Lowest Average Prices
with average_price as (
		select ac.id,
				ac.category_name,
				avg(ap.price) as average_prices
        from amazon_products ap
        join amazon_categories ac
        on ac.id = ap.category_id
        group by ac.id, ac.category_name
        order by average_prices asc
),

# Finding highest average price
highest_average_price as(
		select *
        from average_price
        order by average_prices desc
        limit 1
),

# Finding lowest average price
lowest_average_price as (
		select *
        from average_price
        order by average_prices asc
        limit 1
),

# Calculating total sales and other performance metrics for these categories.
sales_performance as(
		select ap.category_id,
				ac.category_name,
                sum(ap.boughtInLastMonth) as total_sales,
                avg(ap.price) as avg_price,
                avg(ap.stars) as avg_ratings,
                avg(ap.listPrice - ap.price) as avg_profit_margin
        from amazon_products ap
        join amazon_categories ac
        on
        ac.id = ap.category_id
        group by ap.category_id, ac.category_name
        order by ap.category_id asc
),

# Sales performance of highest average price category
hap_sales_performance as (
		select sp.category_id,
				sp.category_name,
                total_sales,
                avg_price,
                avg_ratings,
                avg_profit_margin
        from sales_performance sp
        join highest_average_price hap
        on
        hap.id = sp.category_id
),

# # Sales performance of highest average price category
lap_sales_performance as (
		select sp.category_id,
				sp.category_name,
                total_sales,
                avg_price,
                avg_ratings,
                avg_profit_margin
        from sales_performance sp
        join 
        lowest_average_price lap
        on
        lap.id = sp.category_id
        and
        lap.category_name = sp.category_name
)

# Combining restults to compare
select "Highest Average Price Category" as category_comparison,
		category_id,
        category_name,
        total_sales,
        avg_price,
        avg_ratings,
        avg_profit_margin
from hap_sales_performance

union all

select "Lowest Average Price Category" as category_comparison,
		category_id,
        category_name,
        total_sales,
        avg_price,
        avg_ratings,
        avg_profit_margin
from lap_sales_performance;


# Using subqueries
-- Select sales metrics for categories with the highest average price
select 
    'Highest Average Price Category' AS Category_Type,
    p.category_id,                                    
    c.category_name,                                  
    sum(p.boughtInLastMonth) as total_sold,           
    avg(p.price) as avg_price,                        
    avg(p.stars) as avg_ratings,                      
    avg(p.listPrice - p.price) as avg_profit_margin   
from amazon_products p
join amazon_categories c
    on p.category_id = c.id                           
join (
    -- Subquery to find the category with the highest average price
    select category_id
    from (
        select 
            category_id,
            avg(price) as avg_price
        from amazon_products
        group by category_id
    ) as avg_prices
    order by avg_price desc
    limit 1
) as highest_avg_price
    on p.category_id = highest_avg_price.category_id    
group by p.category_id, c.category_name               

union all

-- Select sales metrics for categories with the lowest average price
select 
    'Lowest Average Price Category' as Category_Type, 
    p.category_id,                                    
    c.category_name,                                  
    sum(p.boughtInLastMonth) as total_sold,           
    avg(p.price) as avg_price,                        
    avg(p.stars) as avg_ratings,                        
    avg(p.listPrice - p.price) as avg_profit_margin     
from amazon_products p
join amazon_categories c
    on p.category_id = c.id                           
join (
    -- Subquery to find the category with the lowest average price
    select category_id
    from (
        select 
            category_id,
            avg(price) as avg_price
        from amazon_products
        group by category_id
    ) as avg_prices
    order by avg_price asc
    limit 1
) as lowest_avg_price
    on p.category_id = lowest_avg_price.category_id   
group by p.category_id, c.category_name               

-- Order results by category type
order by Category_Type;

