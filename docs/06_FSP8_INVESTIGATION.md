# FSP-8 End-to-End Investigation

## Issue

**FSP-8 --- Revenue is duplicated for split-payment orders**

Priority: Highest. Label: `duplicate-revenue`.

## Jira evidence

The issue describes revenue duplication when an order has multiple
successful payments.

Examples in the description: - Order 1001: 2 sales rows × 2 successful
payments = 4 joined rows; expected 2. - Order 1004: 2 sales rows × 3
successful payments = 6 joined rows; expected 2.

## Conflicting evidence

A Jira comment described Order 1004 differently, stating 3 items and 3
payments.

The repository test data/CSV show 2 items and 3 payments.

The investigation surfaces this conflict instead of silently selecting
one statement.

## Snowflake evidence

The current sales/target tables are empty: - `BRONZE.SALES`: 0 -
`SILVER.FACT_SALES`: 0 - `GOLD.VW_SALES_KPI`: 0

Therefore the issue cannot currently be reproduced from populated
Snowflake runtime data.

## GitHub evidence

The Silver transformation: 1. starts from item-grain sales; 2.
aggregates successful payments by `ORDER_ID`; 3. joins the
one-row-per-order payment summary to item-grain sales.

This is the grain-safe pattern for avoiding the many-to-many
multiplication.

## RCA interpretation

Jira documents the many-to-many join as the likely cause. GitHub
provides implementation evidence of the grain-safe aggregation pattern.
Current Snowflake data cannot independently confirm runtime behavior.

The investigation therefore must not claim that production runtime
behavior has been independently validated.

## Business impact

Jira documents revenue overstatement for split-payment orders. A current
runtime financial amount cannot be measured from the empty sales data.

## Regression checks

-   one row per `ORDER_ITEM_ID`;
-   one payment-summary row per `ORDER_ID`;
-   source-to-target reconciliation;
-   Gold-to-Silver reconciliation;
-   split-payment behavior;
-   duplicate detection.

## Main lesson

The POC demonstrates the distinction between **reported behavior,
implemented logic and runtime evidence**.
