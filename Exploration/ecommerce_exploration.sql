-- What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years?

SELECT
  EXTRACT(YEAR from orders.purchase_ts) AS purchase_year
  , EXTRACT(QUARTER from orders.purchase_ts) AS purchase_quarter
  , COUNT(distinct orders.id) AS order_count
  , ROUND(SUM(orders.usd_price)) AS total_sales
  , ROUND(AVG(orders.usd_price)) AS aov
FROM core.orders AS orders
JOIN core.customers AS customers ON
orders.customer_id = customers.id
JOIN core.geo_lookup AS geo ON
customers.country_code = geo.country_code
WHERE
  orders.product_name LIKE '%Macbook%'
  AND geo.region = 'NA'
GROUP BY 1, 2
ORDER BY 1, 2
;

-- How many Macbooks were ordered in USD each month in 2019 through 2020, sorted from oldest to most recent month?

SELECT
  DATE_TRUNC(orders.purchase_ts,month) AS purchase_month
  , COUNT(distinct orders.id) AS order_count
FROM core.orders AS orders
WHERE
  orders.product_name LIKE '%Macbook%'
  AND orders.currency = 'USD'
  AND EXTRACT(YEAR from orders.purchase_ts) IN (2019,2020)
GROUP BY purchase_month
ORDER BY purchase_month
;


-- Return the unique combinations of product IDs and product names of all Apple and Bose products.

SELECT
  DISTINCT product_id
  , product_name
FROM core.orders
WHERE
  product_name LIKE '%Apple%'
  OR product_name LIKE '%Macbook%'
  OR product_name LIKE '%bose%'
ORDER BY product_name
;


-- Return the purchase month, shipping month, time to ship (in days), and product name for each order placed in 2020. Show at least 2 ways of filtering on the date.

SELECT
  EXTRACT(MONTH FROM status.purchase_ts) AS purchase_month
  , EXTRACT(MONTH FROM status.ship_ts) AS ship_month
  , DATE_DIFF(status.ship_ts, status.purchase_ts, day) AS time_to_ship_days
  , orders.product_name AS product_name
FROM core.orders AS orders
JOIN core.order_status AS status
ON orders.id = status.order_id
WHERE EXTRACT(YEAR FROM status.purchase_ts) = 2020
  -- Alternate way:
  -- status.purchase_ts BETWEEN '2020-01-01' AND '2020-12-31'
;


-- What is the average time-to-purchase between loyalty customers vs. non-loyalty customers? Return your results in one query.

SELECT
  customers.loyalty_program
  , ROUND(
      AVG(
        DATE_DIFF(orders.purchase_ts, customers.created_on, day)
        )
    ) AS avg_time_to_purchase_days
  , COUNT(customers.id) AS customer_count
FROM core.orders AS orders
JOIN core.customers AS customers ON orders.customer_id = customers.id
GROUP BY customers.loyalty_program
;


-- What is the average order value per year for products that are either laptops or headphones? Round this to 2 decimals.

SELECT
  EXTRACT(YEAR FROM status.purchase_ts) AS year
  , ROUND(AVG(orders.usd_price)) AS AOV
  , COUNT(orders.id) AS total_orders
FROM core.orders AS orders
JOIN core.order_status AS status ON orders.id = status.order_id
WHERE orders.product_name LIKE '%Macbook%'
  OR orders.product_name LIKE '%Laptop%'
  OR orders.product_name LIKE '%Headphones%'
GROUP BY year
ORDER BY year
;


-- How many customers either came through an email marketing channel and created an account on mobile, or came through an affiliate marketing campaign and created an account on desktop?

SELECT
  COUNT(CASE 
          WHEN customers.marketing_channel = 'email' 
            AND customers.account_creation_method = 'mobile' 
          THEN customers.id 
        END) AS email_mobile_count # email and mobile form an exclusive pairing
  , COUNT(CASE 
            WHEN customers.marketing_channel = 'affiliate' 
              AND customers.account_creation_method = 'desktop' 
            THEN customers.id 
          END) AS affiliate_desktop_count # all affiliate = unknown method; all desktop = direct channel
  , COUNT(customers.id) AS total_count
FROM core.customers AS customers
;

/*
This query revealed a deterministic relationship between marketing_channel and account_creation_method,
meaning each marketing channel is consistently associated with a specific account creation method.
There are no variations or overlaps in these pairings.
Might raise this as a potential data quality issue to the data engineering team.
*/

SELECT 
  customers.marketing_channel
  , customers.account_creation_method
  , COUNT(customers.id) AS combination_count
FROM core.customers AS customers
GROUP BY customers.marketing_channel, customers.account_creation_method
ORDER BY customers.marketing_channel, customers.account_creation_method
;

-- What is the total number of orders per year for each product? Clean up product names when grouping and return in alphabetical order after sorting by months.

SELECT
  EXTRACT(YEAR FROM status.purchase_ts) AS purchase_year
  , EXTRACT(MONTH FROM status.purchase_ts) AS purchase_month
  , TRIM(
      CASE 
      WHEN orders.product_name LIKE '%27in%4k gaming monitor%' THEN '27in 4K gaming monitor'
      ELSE orders.product_name
    END
  ) AS product_name_clean
  , COUNT(orders.id) AS total_orders
FROM core.orders AS orders
JOIN core.order_status AS status
  ON orders.id = status.order_id
GROUP BY purchase_year, purchase_month, product_name_clean
ORDER BY purchase_month, product_name_clean, purchase_year
;