USE DATABASE FINANCE_DEMO_DB;
USE SCHEMA FINANCE_DEMO_DB.GOLD;
USE WAREHOUSE FINANCE_DEMO_WH;
-- ============================================================================
-- 7. SEMANTIC VIEW
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW
    FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW

TABLES (
    sales_kpi AS FINANCE_DEMO_DB.GOLD.VW_SALES_KPI
)

FACTS (
    sales_kpi.order_count AS ORDER_COUNT,
    sales_kpi.unique_customer_count AS UNIQUE_CUSTOMER_COUNT,
    sales_kpi.units_sold AS UNITS_SOLD,
    sales_kpi.gross_revenue AS GROSS_REVENUE,
    sales_kpi.net_revenue AS NET_REVENUE,
    sales_kpi.total_margin AS TOTAL_MARGIN,
    sales_kpi.average_order_value AS AVERAGE_ORDER_VALUE,
    sales_kpi.split_payment_order_count AS SPLIT_PAYMENT_ORDER_COUNT
)

DIMENSIONS (
    sales_kpi.order_date AS ORDER_DATE
        COMMENT = 'Sales transaction date.',
    sales_kpi.year_number AS YEAR_NUMBER,
    sales_kpi.quarter_number AS QUARTER_NUMBER,
    sales_kpi.month_number AS MONTH_NUMBER,
    sales_kpi.month_name AS MONTH_NAME,
    sales_kpi.region AS REGION
        COMMENT = 'Customer sales region.',
    sales_kpi.customer_segment AS CUSTOMER_SEGMENT
        COMMENT = 'Retail, Premium or Corporate customer segment.',
    sales_kpi.product_category AS PRODUCT_CATEGORY,
    sales_kpi.sales_channel AS SALES_CHANNEL
        COMMENT = 'ONLINE or BRANCH.',
    sales_kpi.payment_pattern AS PAYMENT_PATTERN
        COMMENT = 'SINGLE_PAYMENT, SPLIT_PAYMENT or NO_SUCCESSFUL_PAYMENT.'
)

METRICS (
    sales_kpi.total_orders AS
        SUM(ORDER_COUNT)
        COMMENT = 'Total aggregated order count.',

    sales_kpi.total_customers AS
        SUM(UNIQUE_CUSTOMER_COUNT)
        COMMENT = 'Aggregated customer count across selected groups.',

    sales_kpi.total_units AS
        SUM(UNITS_SOLD)
        COMMENT = 'Total units sold.',

    sales_kpi.total_gross_revenue AS
        SUM(GROSS_REVENUE)
        COMMENT = 'Total gross revenue.',

    sales_kpi.total_net_revenue AS
        SUM(NET_REVENUE)
        COMMENT = 'Total net revenue after discounts and taxes.',

    sales_kpi.total_margin_value AS
        SUM(TOTAL_MARGIN)
        COMMENT = 'Total estimated sales margin.',

    sales_kpi.total_split_payment_orders AS
        SUM(SPLIT_PAYMENT_ORDER_COUNT)
        COMMENT = 'Aggregated split-payment order count.'
);