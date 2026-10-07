-- ============================================================
-- Olist E-Commerce Delivery & Customer Intelligence Analysis
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Tools: MySQL
-- ============================================================

USE olist_ecommerce;


-- ============================================================
-- 1. DATA QUALITY & ORDER STATUS
-- ============================================================

-- Check total orders and missing key fields
SELECT
    COUNT(*) AS total_orders,
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(order_status IS NULL) AS missing_order_status,
    SUM(order_purchase_timestamp IS NULL) AS missing_purchase_date,
    SUM(order_delivered_customer_date IS NULL) AS missing_delivery_date,
    SUM(order_estimated_delivery_date IS NULL) AS missing_estimated_date
FROM orders;


-- Check for duplicate order IDs
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Order status distribution
SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- ============================================================
-- 2. OVERALL LATE-DELIVERY PERFORMANCE
-- ============================================================

-- Measure the overall late-delivery rate among delivered orders
SELECT
    COUNT(*) AS delivered_orders,
    SUM(
        order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * SUM(
            order_delivered_customer_date > order_estimated_delivery_date
        ) / COUNT(*),
        2
    ) AS late_delivery_rate_pct
FROM orders
WHERE order_status = 'delivered';


-- Late-delivery rate by customer state
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    SUM(
        o.order_delivered_customer_date > o.order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * SUM(
            o.order_delivered_customer_date > o.order_estimated_delivery_date
        ) / COUNT(*),
        2
    ) AS late_delivery_rate_pct
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY late_delivery_rate_pct DESC;

-- ============================================================
-- 3. DELIVERY PERFORMANCE & CUSTOMER SATISFACTION
-- ============================================================

-- Compare customer review scores for late vs on-time deliveries
SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On Time'
    END AS delivery_performance,
    COUNT(*) AS review_count,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_performance;

-- ============================================================
-- 4. RFM CUSTOMER SEGMENTATION
-- ============================================================

-- Calculate customer-level Recency, Frequency and Monetary value
WITH customer_rfm AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price + oi.freight_value) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    last_purchase_date,
    frequency,
    ROUND(monetary, 2) AS monetary
FROM customer_rfm
LIMIT 20;


-- Assign customers to five RFM scoring groups
WITH customer_rfm AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price + oi.freight_value) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    last_purchase_date,
    frequency,
    ROUND(monetary, 2) AS monetary,
    NTILE(5) OVER (ORDER BY last_purchase_date) AS recency_score,
    NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
    NTILE(5) OVER (ORDER BY monetary) AS monetary_score
FROM customer_rfm
LIMIT 20;


-- Identify the distribution of RFM segments
WITH customer_rfm AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price + oi.freight_value) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

rfm_scores AS (
    SELECT
        customer_unique_id,
        NTILE(5) OVER (ORDER BY last_purchase_date) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary) AS monetary_score
    FROM customer_rfm
)

SELECT
    CONCAT(
        recency_score,
        frequency_score,
        monetary_score
    ) AS rfm_score,
    COUNT(*) AS customer_count
FROM rfm_scores
GROUP BY rfm_score
ORDER BY customer_count DESC;


-- Compare selected RFM segments by customer value
WITH customer_rfm AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price + oi.freight_value) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

rfm_scores AS (
    SELECT
        customer_unique_id,
        monetary,
        NTILE(5) OVER (ORDER BY last_purchase_date) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary) AS monetary_score
    FROM customer_rfm
)

SELECT
    CONCAT(
        recency_score,
        frequency_score,
        monetary_score
    ) AS rfm_score,
    COUNT(*) AS customer_count,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(AVG(monetary), 2) AS avg_customer_value
FROM rfm_scores
GROUP BY rfm_score
HAVING rfm_score IN ('555', '131', '132')
ORDER BY total_revenue DESC;

-- ============================================================
-- 5. FIRST-ORDER DELIVERY & REPEAT PURCHASE BEHAVIOR
-- ============================================================

-- Compare repeat-purchase rates based on first-order delivery performance
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS order_number
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),

first_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 'Late'
            ELSE 'On Time'
        END AS first_order_delivery
    FROM customer_orders
    WHERE order_number = 1
),

customer_repeat AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS total_orders
    FROM customer_orders
    GROUP BY customer_unique_id
)

SELECT
    f.first_order_delivery,
    COUNT(*) AS customers,
    SUM(
        CASE
            WHEN r.total_orders > 1 THEN 1
            ELSE 0
        END
    ) AS repeat_customers,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN r.total_orders > 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS repeat_purchase_rate_pct
FROM first_orders f
JOIN customer_repeat r
    ON f.customer_unique_id = r.customer_unique_id
GROUP BY f.first_order_delivery;

-- ============================================================
-- 6. SELLER DELIVERY PERFORMANCE
-- ============================================================

-- Identify sellers with the highest late-delivery rates.
-- Minimum threshold of 50 delivered orders avoids very small samples.

SELECT
    oi.seller_id,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(
        o.order_delivered_customer_date > o.order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * SUM(
            o.order_delivered_customer_date > o.order_estimated_delivery_date
        ) / COUNT(DISTINCT o.order_id),
        2
    ) AS late_delivery_rate_pct
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT o.order_id) >= 50
ORDER BY late_delivery_rate_pct DESC
LIMIT 15;

-- ============================================================
-- END OF ANALYSIS
-- ============================================================
