
----------------Count each customer in city and state----------

select 
ocd.customer_city  ,
ocd.customer_state  , 
count (*) as   City_Count
from olist_customers_dataset ocd 
group by ocd.customer_city,
ocd.customer_state 
order by count(*) desc ;

go 

------------- : What is the volume of the order each day --------

select
    order_purchase_timestamp::date,
    Count(*)
from olist_orders_dataset
group by order_purchase_timestamp::date
order by order_purchase_timestamp::date desc 
go 

--------------- Most popular day were--------------
select
    order_purchase_timestamp::date,
    Count(*)
from olist_orders_dataset
group by order_purchase_timestamp::date
order by count(*) desc 

---------- Popular categories  Most Ordered Products ---------------
select p.product_category_name , count(o.order_item_id ) as CountOrder
from olist_products_dataset p 
inner join olist_order_items_dataset o 
on p.product_id = o.product_id
group by(p.product_category_name)
order by CountOrder desc
limit 5;

-------------FIND THE ESITMATE AND ACUTAL DATE ACCURACY------------

SELECT 
date_part('year', order_purchase_timestamp::timestamp) as order_year,
date_part('month', order_purchase_timestamp::timestamp) as order_month,
avg(justify_interval(order_estimated_delivery_date::timestamp - order_delivered_customer_date::timestamp)) as Date_Diff
from olist_orders_dataset 
where order_status  = 'Delivered'
GROUP BY
     order_year, order_month

ORDER BY
    order_year, order_month;


----------------Imporve deliver process -----------


WITH avg_delivery_diff AS (
    SELECT 
        AVG(justify_interval(order_estimated_delivery_date::timestamp - order_delivered_customer_date::timestamp)) AS overall_avg_diff
    FROM olist_orders_dataset 
    WHERE order_status = 'Delivered'
        AND order_estimated_delivery_date IS NOT NULL 
        AND order_delivered_customer_date IS NOT NULL
),
product_delivery_performance AS (
    SELECT 
        p.product_id,
        p.product_category_name,
        o.order_id,
        ord.order_purchase_timestamp,
        ord.order_estimated_delivery_date,
        ord.order_delivered_customer_date,
        justify_interval(ord.order_estimated_delivery_date::timestamp - ord.order_delivered_customer_date::timestamp) AS delivery_diff
    FROM olist_products_dataset p
    INNER JOIN olist_order_items_dataset o ON p.product_id = o.product_id
    INNER JOIN olist_orders_dataset ord ON o.order_id = ord.order_id
    WHERE ord.order_status = 'Delivered'
        AND ord.order_estimated_delivery_date IS NOT NULL 
        AND ord.order_delivered_customer_date IS NOT NULL
)
SELECT 
    pdp.product_id,
    pdp.product_category_name,
    pdp.order_id,
    pdp.order_purchase_timestamp,
    pdp.order_estimated_delivery_date,
    pdp.order_delivered_customer_date,
    pdp.delivery_diff,
    add.overall_avg_diff
FROM product_delivery_performance pdp
CROSS JOIN avg_delivery_diff add
WHERE pdp.delivery_diff > add.overall_avg_diff
ORDER BY pdp.delivery_diff DESC;
