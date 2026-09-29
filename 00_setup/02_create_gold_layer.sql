
USE DATABASE FINANCE_DEMO_DB;
USE SCHEMA FINANCE_DEMO_DB.GOLD;
USE WAREHOUSE FINANCE_DEMO_WH;
-- ============================================================================
-- 6. GOLD KPI VIEW
-- ============================================================================
-- Grain:
-- One row per ORDER_DATE + REGION + PRODUCT_CATEGORY + SALES_CHANNEL.
--
-- Includes aggregated business KPIs.

CREATE OR REPLACE VIEW FINANCE_DEMO_DB.GOLD.VW_SALES_KPI AS
SELECT
    F.ORDER_DATE,
    D.YEAR_NUMBER,
    D.QUARTER_NUMBER,
    D.MONTH_NUMBER,
    D.MONTH_NAME,

    C.REGION,
    C.CUSTOMER_SEGMENT,
    P.PRODUCT_CATEGORY,
    F.SALES_CHANNEL,
    F.PAYMENT_PATTERN,

    COUNT(DISTINCT F.ORDER_ID) AS ORDER_COUNT,
    COUNT(DISTINCT F.CUSTOMER_ID) AS UNIQUE_CUSTOMER_COUNT,
    SUM(F.QUANTITY) AS UNITS_SOLD,

    ROUND(
        SUM(
            IFF(
                F.ORDER_STATUS = 'COMPLETED',
                F.GROSS_SALES_AMOUNT,
                0
            )
        ),
        2
    ) AS GROSS_REVENUE,

    ROUND(
        SUM(
            IFF(
                F.ORDER_STATUS = 'COMPLETED',
                F.NET_SALES_AMOUNT,
                0
            )
        ),
        2
    ) AS NET_REVENUE,

    ROUND(
        SUM(
            IFF(
                F.ORDER_STATUS = 'COMPLETED',
                F.MARGIN_AMOUNT,
                0
            )
        ),
        2
    ) AS TOTAL_MARGIN,

    ROUND(
        SUM(
            IFF(
                F.ORDER_STATUS = 'COMPLETED',
                F.NET_SALES_AMOUNT,
                0
            )
        )
        / NULLIF(
            COUNT(
                DISTINCT IFF(
                    F.ORDER_STATUS = 'COMPLETED',
                    F.ORDER_ID,
                    NULL
                )
            ),
            0
        ),
        2
    ) AS AVERAGE_ORDER_VALUE,

    COUNT(
        DISTINCT IFF(
            F.ORDER_STATUS = 'COMPLETED'
            AND F.PAYMENT_PATTERN = 'SPLIT_PAYMENT',
            F.ORDER_ID,
            NULL
        )
    ) AS SPLIT_PAYMENT_ORDER_COUNT

FROM FINANCE_DEMO_DB.SILVER.FACT_SALES F
JOIN FINANCE_DEMO_DB.SILVER.DIM_CUSTOMER C
    ON F.CUSTOMER_ID = C.CUSTOMER_ID
JOIN FINANCE_DEMO_DB.SILVER.DIM_PRODUCT P
    ON F.PRODUCT_ID = P.PRODUCT_ID
JOIN FINANCE_DEMO_DB.SILVER.DIM_DATE D
    ON F.ORDER_DATE = D.DATE_KEY

GROUP BY
    F.ORDER_DATE,
    D.YEAR_NUMBER,
    D.QUARTER_NUMBER,
    D.MONTH_NUMBER,
    D.MONTH_NAME,
    C.REGION,
    C.CUSTOMER_SEGMENT,
    P.PRODUCT_CATEGORY,
    F.SALES_CHANNEL,
    F.PAYMENT_PATTERN;
