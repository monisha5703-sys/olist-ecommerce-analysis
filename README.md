# Olist E-Commerce Delivery & Customer Intelligence Analysis

## Project Overview

This project analyzes the Brazilian E-Commerce Public Dataset by Olist to evaluate delivery performance, customer satisfaction, customer value, repeat purchasing, and seller performance.

The project uses MySQL to transform raw e-commerce data into business-focused insights that can support delivery operations, customer retention, and seller performance management.

---

## Business Objective

The objective is to understand:

- How frequently orders are delivered late
- Which customer regions experience higher late-delivery rates
- Whether late deliveries are associated with lower customer review scores
- Which customers represent the highest-value segments
- Whether first-order delivery performance is associated with repeat purchasing
- Which sellers have elevated late-delivery rates

---

## Dataset

**Dataset:** Brazilian E-Commerce Public Dataset by Olist

The analysis uses the following tables:

- `orders`
- `customers`
- `order_items`
- `reviews`

The dataset contains anonymized Brazilian e-commerce transactions and customer reviews.

---

## Tools & Technologies

- **MySQL**
- SQL
- Common Table Expressions (CTEs)
- Window Functions
- `NTILE()`
- `ROW_NUMBER()`
- Aggregations
- `CASE WHEN`
- Multi-table Joins

---

## Key Analyses

### 1. Data Quality & Order Status

Checked:

- Missing values in key order fields
- Duplicate order IDs
- Order-status distribution

### 2. Delivery Performance

Calculated the overall late-delivery rate and compared late-delivery performance across customer states.

**Overall late-delivery rate: 8.11%**

### 3. Delivery Performance & Customer Satisfaction

Compared average review scores between late and on-time deliveries.

| Delivery Performance | Reviews | Average Review Score |
|---|---:|---:|
| On Time | 88,660 | 4.29 |
| Late | 7,700 | 2.57 |

**Finding:** Late deliveries were associated with substantially lower customer review scores.

**Business implication:** Delivery reliability appears to be an important component of customer experience.

### 4. RFM Customer Segmentation

Customers were segmented using:

- **Recency** — how recently they purchased
- **Frequency** — how often they purchased
- **Monetary** — how much they spent

The analysis identified **364 customers** in the top `555` RFM segment.

The 555 segment had an average customer value of **R$454.87**, compared with:

- R$70.98 for segment `132`
- R$39.71 for segment `131`

**Finding:** A relatively small group of highly engaged customers had substantially higher historical customer value.

### 5. First-Order Delivery & Repeat Purchasing

Compared repeat-purchase rates based on whether a customer's first delivered order was late or on time.

| First Order Delivery | Customers | Repeat Customers | Repeat Rate |
|---|---:|---:|---:|
| On Time | 85,754 | 2,610 | 3.04% |
| Late | 7,604 | 191 | 2.51% |

**Finding:** Customers with an on-time first order had a slightly higher repeat-purchase rate.

**Important:** This analysis shows an association, not causation.

### 6. Seller Delivery Performance

Analyzed sellers with at least 50 delivered orders to avoid relying on very small samples.

The highest late-delivery rate among qualifying sellers was **35.62%**.

One high-volume seller recorded:

- 389 delivered orders
- 95 late orders
- 24.42% late-delivery rate

**Finding:** Seller delivery performance varies substantially, creating opportunities for targeted operational review.

---

## Key Business Recommendations

### Improve Delivery Reliability

Prioritize regions and operational areas with consistently high late-delivery rates.

### Protect High-Value Customers

Use RFM segmentation to identify highly engaged customers and prioritize retention initiatives.

### Monitor Seller Performance

Review sellers with elevated late-delivery rates, particularly when poor performance affects a meaningful order volume.

### Protect the First Customer Experience

Prioritize reliable first-order delivery because customers with on-time first orders showed a higher repeat-purchase rate.

---

## Limitations

- The analysis is observational and does not establish causation.
- RFM describes historical customer behavior and does not independently predict future customer value.
- Seller-level delivery performance may also be influenced by geography, carrier performance, product characteristics, and other operational factors.
- The analysis focuses on selected tables from the Olist dataset rather than every available dataset table.

---

## Project Structure

```text
olist-ecommerce-analysis/
│
├── olist_ecommerce_analysis.sql
└── README.md
