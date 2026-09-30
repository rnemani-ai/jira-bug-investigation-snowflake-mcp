# FSP-8 End-to-End Investigation

## 1. Case Study Purpose

This document provides the detailed end-to-end investigation of the representative Jira issue:

> **FSP-8 — Revenue is duplicated for split-payment orders**

FSP-8 was selected because it exercises the complete architecture:

```text
Jira
  ↓
Cortex Agent
  ↓
Snowflake runtime investigation
  ↓
GitHub implementation investigation
  ↓
Evidence reconciliation
  ↓
Root-cause classification
  ↓
Business-impact classification
  ↓
Resolution guidance
  ↓
Regression-test guidance
```

The investigation also demonstrates the most important governance principle in the project:

> **The Agent must distinguish documented issue information, implementation evidence, and actual runtime evidence.**

---

# 2. Jira Issue

## Issue Key

```text
FSP-8
```

## Summary

```text
Revenue is duplicated for split-payment orders
```

## Priority

```text
Highest
```

## Label

```text
duplicate-revenue
```

## Status

```text
To Do
```

---

# 3. Affected Snowflake Objects

The Jira issue identifies these affected objects:

```text
FINANCE_DEMO_DB.BRONZE.SALES

FINANCE_DEMO_DB.BRONZE.PAYMENTS

FINANCE_DEMO_DB.SILVER.FACT_SALES

FINANCE_DEMO_DB.GOLD.VW_SALES_KPI
```

The investigation therefore follows the data path:

```text
BRONZE.SALES
      +
BRONZE.PAYMENTS
      ↓
SILVER.FACT_SALES
      ↓
GOLD.VW_SALES_KPI
```

---

# 4. Reported Problem

The Jira issue describes a revenue-overstatement problem associated with orders completed using multiple successful payment methods.

The reported behavior is:

```text
Single-payment orders appear correct.

Split-payment orders can produce duplicated revenue.
```

The reported mechanism is a direct join between sales and payments using:

```text
ORDER_ID
```

followed by aggregation of sales revenue.

---

# 5. Jira Reproduction Scenario

The documented reproduction pattern is:

```text
1. Join SILVER.FACT_SALES directly to BRONZE.PAYMENTS on ORDER_ID.
2. Filter PAYMENT_STATUS = 'SUCCESS'.
3. Aggregate NET_SALES_AMOUNT.
4. Compare the result with SILVER.FACT_SALES.
```

The expected behavior is:

```text
Revenue is counted once per ORDER_ITEM_ID.
```

And:

```text
Gold totals match Silver totals.
```

---

# 6. Reported Actual Behavior

The Jira description gives two representative split-payment examples.

## Order 1001

```text
Sales rows:             2
Successful payments:    2
Joined rows:            4
Expected joined rows:   2
```

The multiplication is:

```text
2 × 2 = 4
```

---

## Order 1004

```text
Sales rows:             2
Successful payments:    3
Joined rows:            6
Expected joined rows:   2
```

The multiplication is:

```text
2 × 3 = 6
```

The described pattern is therefore:

```text
item-grain sales
       ×
payment-grain records
       ↓
many-to-many multiplication
```

---

# 7. Reported Expected Result

The Jira acceptance criteria require:

```text
1. Payments are aggregated to one row per ORDER_ID before joining.
2. FACT_SALES remains one row per ORDER_ITEM_ID.
3. Gold revenue matches Silver revenue.
4. Split-payment orders do not duplicate revenue.
```

These acceptance criteria became the technical validation targets for the investigation.

---

# 8. First Investigation Step — Retrieve Jira

The Cortex Agent first uses the Atlassian Jira MCP connection.

The purpose is to establish:

```text
What is the reported issue?
What behavior is expected?
What behavior is reported?
What objects are affected?
What reproduction steps are documented?
What acceptance criteria are documented?
```

At this point the information is classified as:

```text
Documented evidence
```

It is not yet treated as independently reproduced Snowflake behavior.

---

# 9. Second Investigation Step — Check Snowflake Runtime

The Agent then checks the relevant Snowflake objects.

The runtime state observed during the investigation was:

| Object | Current state |
|---|---:|
| `BRONZE.SALES` | 0 rows |
| `BRONZE.PAYMENTS` | 8 rows |
| `SILVER.FACT_SALES` | 0 rows |
| `GOLD.VW_SALES_KPI` | 0 rows |

This is one of the most important findings in the investigation.

The payment table contains current data.

The sales, fact, and Gold objects needed to reproduce the full reported revenue behavior are empty.

---

# 10. Runtime Validation Boundary

Because:

```text
BRONZE.SALES = 0
```

the Agent cannot construct a current runtime reproduction of the documented sales/payment multiplication.

Because:

```text
SILVER.FACT_SALES = 0
```

the Agent also cannot perform the intended source-to-fact revenue reconciliation.

Because:

```text
GOLD.VW_SALES_KPI = 0
```

the Agent cannot independently validate the reported Gold revenue overstatement.

Therefore:

> **End-to-end runtime reproduction of FSP-8 is blocked by the current Snowflake data state.**

This is not a failure of the investigation.

It is an evidence boundary that must be reported.

---

# 11. What the Agent Must Not Do

The Agent must not:

- invent sales rows
- create simulated runtime results
- treat repository test data as current Snowflake data
- claim the revenue duplication was reproduced
- claim Gold revenue was validated
- claim the fix passed runtime testing

The skill explicitly prevents these behaviors.

---

# 12. Third Investigation Step — Determine Data Grain

The next step is grain analysis.

## Sales

```text
BRONZE.SALES
```

is at:

```text
ORDER_ITEM_ID
```

grain.

One order can therefore contain multiple sales rows.

---

## Payments

```text
BRONZE.PAYMENTS
```

is at:

```text
PAYMENT_ID
```

grain.

One order can contain multiple payment rows.

---

## Core Relationship

The relevant relationship is:

```text
ORDER_ID
   │
   ├── multiple ORDER_ITEM_ID values
   │
   └── multiple PAYMENT_ID values
```

Therefore:

```text
ORDER_ID
```

does not uniquely identify either side.

This is the fundamental reason a direct join can multiply rows.

---

# 13. Demonstrating the Many-to-Many Problem

Consider Order 1001.

```text
Sales:

ORDER_ITEM_ID
-------------
1001-1
1001-2
```

Two rows.

Payments:

```text
PAYMENT_ID
----------
P1001
P1002
```

Two successful payment rows.

A direct join:

```sql
sales
JOIN payments
  ON sales.order_id = payments.order_id
```

creates:

```text
1001-1 × P1001
1001-1 × P1002
1001-2 × P1001
1001-2 × P1002
```

Total:

```text
4 rows
```

The sales revenue can therefore be repeated across the four joined rows.

---

# 14. Order 1004

The documented Order 1004 example has:

```text
2 sales items
3 successful payments
```

A direct join can create:

```text
2 × 3 = 6 rows
```

The correct item-level fact grain should remain:

```text
2 rows
```

This is the same cardinality problem with a larger payment count.

---

# 15. Fourth Investigation Step — Inspect GitHub

Because current Snowflake sales/fact/gold data is empty, the Agent needs another evidence source to inspect implementation behavior.

The Agent uses:

```text
GITHUB_BUG_INVESTIGATION
```

The relevant repository is:

```text
rnemani-ai/jira-bug-investigation-snowflake-mcp
```

The key transformation examined during the investigation is:

```text
00_setup/01_create_silver_layer.sql
```

---

# 16. GitHub Transformation Finding

The implementation uses a payment-summary pattern.

Conceptually:

```text
BRONZE.PAYMENTS
       ↓
Filter successful payments
       ↓
GROUP BY ORDER_ID
       ↓
PAYMENT_SUMMARY
       ↓
Join to sales
```

The important property is:

```text
one payment-summary row per ORDER_ID
```

rather than:

```text
one row per PAYMENT_ID
```

during the final sales join.

---

# 17. Why the Payment Summary Prevents Multiplication

Without aggregation:

```text
2 sales items
×
3 payments
=
6 joined rows
```

With payment aggregation:

```text
2 sales items
×
1 payment-summary row
=
2 joined rows
```

The payment-level details are summarized before the join.

The sales fact therefore remains at:

```text
ORDER_ITEM_ID
```

grain.

---

# 18. Payment Summary Is a Transformation Pattern

An important implementation detail is that:

```text
PAYMENT_SUMMARY
```

is a transformation/CTE pattern in the current implementation.

It should not be described as a separate persistent Silver table.

The logical flow is:

```text
BRONZE.PAYMENTS
       ↓
payment aggregation CTE
       ↓
sales transformation
       ↓
SILVER.FACT_SALES
```

---

# 19. Payment Attributes in FACT_SALES

The fact transformation supports payment-derived fields such as:

```text
SUCCESSFUL_PAYMENT_COUNT
SUCCESSFUL_PAYMENT_AMOUNT
PAYMENT_METHODS
PAYMENT_PATTERN
```

These fields provide payment context while preserving the fact-table grain.

The design therefore separates:

```text
payment-level source data
```

from:

```text
item-level fact grain
```

---

# 20. GitHub Test Data

The repository test data supports the split-payment scenarios.

## Order 1001

```text
2 items
2 payments
```

## Order 1004

```text
2 items
3 payments
```

This supports the multiplication examples described by the Jira issue.

However:

> GitHub test data is implementation/test evidence, not current Snowflake runtime evidence.

That distinction is preserved throughout the investigation.

---

# 21. Evidence Reconciliation

At this point the Agent has four relevant evidence categories:

```text
Jira
Snowflake
GitHub transformation
GitHub test data
```

They answer different questions.

| Source | What it establishes |
|---|---|
| Jira description | Documented problem and expected behavior |
| Jira comments | Additional documented statements |
| Snowflake | Current runtime data state |
| GitHub SQL | Implementation logic |
| GitHub test data | Repository test/supporting examples |

---

# 22. Evidence Conflict — Order 1004

The investigation found an inconsistency in Jira around Order 1004.

The issue description states:

```text
2 sales rows
3 successful payments
6 joined rows
```

A Jira comment contains a different item-count statement.

The GitHub test data supports:

```text
2 items
3 payments
```

The current Snowflake sales table is empty.

Therefore the runtime cannot independently resolve the Jira discrepancy.

The Agent must surface the conflict rather than silently choosing one statement.

---

# 23. How the Conflict Is Reported

The correct evidence-aware interpretation is:

```text
Jira description:
2 items + 3 payments.

Jira comment:
different item-count statement.

GitHub test data:
2 items + 3 payments.

Snowflake SALES:
empty, so runtime cannot independently resolve the discrepancy.
```

The repository evidence can corroborate the Jira description, but it should not be described as current production/runtime truth.

---

# 24. Technical Root Cause

The technical mechanism supported by the investigation is:

> A direct join between item-grain sales and payment-grain records on `ORDER_ID` can create a many-to-many relationship and multiply sales rows for split-payment orders.

The grain relationship is:

```text
Sales:
ORDER_ITEM_ID

Payments:
PAYMENT_ID

Common business key:
ORDER_ID
```

Because `ORDER_ID` is not unique on either side, a direct join can multiply records.

---

# 25. Implementation Finding

The GitHub transformation contains the expected prevention pattern:

```text
Successful payments
       ↓
Aggregate by ORDER_ID
       ↓
One payment summary per order
       ↓
Join to item-grain sales
       ↓
FACT_SALES remains ORDER_ITEM_ID grain
```

Therefore the investigation establishes:

```text
Fix logic confirmed in transformation.
```

It does not establish:

```text
Runtime behavior validated.
```

---

# 26. RCA Classification

The investigation should preserve the distinction between implementation evidence and runtime validation.

The technical mechanism is supported by:

```text
Jira reproduction description
+
grain analysis
+
GitHub transformation
+
GitHub test data
```

However:

```text
BRONZE.SALES = 0
SILVER.FACT_SALES = 0
GOLD.VW_SALES_KPI = 0
```

prevents current end-to-end runtime reproduction.

Therefore the investigation should not claim a current runtime-confirmed RCA.

The appropriate evidence-aware characterization is:

```text
Documented Root Cause — Not Reproducible
```

when the documented issue/root-cause mechanism is being reported together with the current runtime limitation.

---

# 27. Business Impact

The issue is documented as a revenue-overstatement problem.

The mechanism could cause:

```text
Revenue
   ↓
Repeated across multiplied joined rows
   ↓
Aggregated revenue overstated
```

However, current runtime data does not contain the populated sales/fact/gold records required to calculate the current financial impact.

Therefore the investigation must not invent:

```text
Current dollar impact
Current percentage impact
Current number of affected orders
```

unless those values are independently supported.

---

# 28. Business-Impact Classification

For the current investigation state:

```text
Documented
```

is appropriate for the Jira-reported business impact.

A current runtime-measured impact is:

```text
Not Quantifiable with Current Data
```

because the required runtime sales/fact/gold data is empty.

This distinction is important for finance-facing reporting.

---

# 29. Resolution Guidance

The safe technical resolution is:

```text
Aggregate successful payment records to one row per ORDER_ID
before joining them to item-grain sales.
```

The intended flow is:

```text
PAYMENTS
   ↓
SUCCESS filter
   ↓
GROUP BY ORDER_ID
   ↓
Payment summary
   ↓
Join to SALES
   ↓
FACT_SALES
```

The fact table remains:

```text
ORDER_ITEM_ID
```

grain.

---

# 30. Why the Resolution Is Grain-Safe

The resolution preserves the grain of the fact table.

Instead of:

```text
ORDER_ITEM_ID
      ×
PAYMENT_ID
```

the relationship becomes:

```text
ORDER_ITEM_ID
      +
ORDER_ID-level payment summary
```

Therefore payment information can be attached to each item without multiplying the number of item rows.

---

# 31. Regression Test 1 — Fact Grain

The first test should verify:

```text
one FACT_SALES row per ORDER_ITEM_ID
```

Conceptually:

```sql
SELECT
    ORDER_ITEM_ID,
    COUNT(*) AS row_count
FROM SILVER.FACT_SALES
GROUP BY ORDER_ITEM_ID
HAVING COUNT(*) > 1;
```

Expected result:

```text
No duplicate ORDER_ITEM_ID values.
```

The exact test should be adapted to the project's final SQL implementation.

---

# 32. Regression Test 2 — Payment Aggregation

Verify that the payment summary produces:

```text
one row per ORDER_ID
```

Conceptually:

```sql
SELECT
    ORDER_ID,
    COUNT(*) AS payment_summary_rows
FROM <payment_summary>
GROUP BY ORDER_ID
HAVING COUNT(*) > 1;
```

Expected result:

```text
No duplicate ORDER_ID values in the payment summary.
```

Because `PAYMENT_SUMMARY` is a transformation/CTE, the exact test should be applied against the corresponding transformation logic or an equivalent validation query.

---

# 33. Regression Test 3 — Split-Payment Orders

Identify orders with:

```text
SUCCESSFUL_PAYMENT_COUNT > 1
```

Then validate that:

```text
FACT_SALES row count
```

still matches the expected order-item count.

This specifically targets the class of defect represented by FSP-8.

---

# 34. Regression Test 4 — Source-to-Fact Reconciliation

Compare relevant sales measures between the source and Silver fact.

The goal is to establish:

```text
Source sales amount
        =
FACT_SALES amount
```

for the appropriate grain and filtering rules.

The exact business measure must be taken from the actual project transformation rather than invented.

---

# 35. Regression Test 5 — Gold-to-Silver Reconciliation

Validate:

```text
Gold revenue
=
Silver revenue
```

for the corresponding aggregation/filter context.

This directly addresses the FSP-8 acceptance criterion:

```text
Gold revenue matches Silver revenue.
```

---

# 36. Regression Test 6 — Duplicate Detection

A generic duplicate-detection check should identify unexpected multiplication.

For example:

```text
Expected:
one fact row per ORDER_ITEM_ID

Actual:
more than one fact row per ORDER_ITEM_ID
```

Any returned duplicates should trigger investigation.

---

# 37. Current Runtime Limitation

The regression tests cannot all be meaningfully executed against the current empty runtime.

The current state is:

```text
SALES          = 0 rows
FACT_SALES     = 0 rows
GOLD           = 0 rows
```

Therefore:

```text
Runtime reproduction
and
runtime fix validation
```

remain blocked.

The Agent must distinguish:

```text
Test design exists
```

from:

```text
Test executed successfully against populated runtime data
```

---

# 38. What Was Proven

The investigation provides evidence for the following:

### 1. The Jira issue is documented

FSP-8 reports revenue duplication for split-payment orders.

### 2. The grain relationship can create many-to-many multiplication

Sales are item-grain and payments are payment-grain.

### 3. The repository contains the expected payment aggregation pattern

Successful payments are summarized by `ORDER_ID` before joining to sales.

### 4. Repository test data supports the described split-payment scenarios

Order 1001:

```text
2 items
2 payments
```

Order 1004:

```text
2 items
3 payments
```

### 5. Current Snowflake runtime is incomplete for end-to-end reproduction

Sales, fact, and Gold are empty.

---

# 39. What Was Not Proven

The investigation does not prove:

```text
The current Snowflake runtime reproduces the FSP-8 revenue overstatement.

The current deployed transformation has passed runtime validation.

Gold revenue currently contains the documented overstatement.

The current production financial impact is X dollars.

The current production financial impact is Y percent.

The fix is deployed to a production environment.
```

These statements require additional evidence.

---

# 40. Evidence Matrix

| Investigation Question | Evidence | Classification |
|---|---|---|
| What is the reported issue? | Jira FSP-8 | Documented |
| What is expected? | Jira acceptance criteria | Documented |
| What is the reported multiplication? | Jira description | Documented |
| What is the sales grain? | Snowflake/GitHub implementation | Supported |
| What is the payment grain? | Snowflake/GitHub implementation | Supported |
| Does the many-to-many mechanism make technical sense? | Grain + join analysis | Supported |
| Does GitHub contain payment aggregation? | Transformation SQL | Confirmed in implementation |
| Does current Snowflake reproduce the issue? | SALES/FACT/Gold empty | Blocked |
| Does current runtime validate the fix? | Required runtime data empty | Blocked |
| Does repository test data support the examples? | GitHub test data | Supporting |
| Is Order 1004 completely consistent across sources? | Jira conflict | No |
| Can current financial impact be measured? | Runtime data unavailable | Not quantifiable with current data |

---

# 41. Agent Response Structure for FSP-8

The investigation skill encourages a response structure similar to:

```text
Executive Summary
        ↓
Jira-Documented Evidence
        ↓
Snowflake Runtime Findings
        ↓
GitHub Implementation Findings
        ↓
Evidence Conflicts
        ↓
RCA Classification
        ↓
Business Impact
        ↓
Resolution
        ↓
Regression Tests
        ↓
Limitations
```

This makes the result useful to both technical and business audiences.

---

# 42. Data Engineer View

A Data Engineer primarily needs:

```text
Table grain
Join behavior
Transformation logic
Runtime availability
Regression tests
```

The investigation therefore emphasizes:

```text
ORDER_ITEM_ID
PAYMENT_ID
ORDER_ID
many-to-many multiplication
payment aggregation
FACT_SALES grain
```

---

# 43. Finance Analyst View

A Finance Analyst primarily needs:

```text
What is wrong with revenue?
Which orders are affected?
Can the impact be measured?
Is the current result trustworthy?
```

The Agent should therefore explain:

```text
Split payments can create duplicated revenue when payment rows multiply sales rows.

The current Snowflake runtime does not contain populated sales/fact/Gold data,
so current financial impact cannot be independently measured.
```

---

# 44. Engineering Manager View

An Engineering Manager needs:

```text
RCA status
Evidence confidence
Runtime status
Risk
Resolution
Next action
```

The investigation therefore summarizes:

```text
Documented issue
+
implementation evidence
+
runtime validation blocked
+
grain-safe resolution pattern
+
regression-test requirements
```

---

# 45. Jira Update Governance

If the investigation is converted into a Jira comment, the Agent must first display the proposed comment.

The required boundary is:

```text
This comment has NOT been posted to Jira.

Would you like me to post this comment to Jira?
```

No Jira write should occur before explicit user approval.

---

# 46. Example Proposed Jira Comment Structure

A safe proposed update would contain:

```text
Investigation Summary

- Jira documents revenue duplication for split-payment orders.
- Sales are item-grain and payments are payment-grain.
- The documented join pattern can create many-to-many multiplication.
- Repository transformation code aggregates successful payments by ORDER_ID before joining to sales.
- Current Snowflake SALES, FACT_SALES and Gold data are empty, so runtime reproduction is blocked.
- GitHub test data supports the documented 1001 and 1004 examples.
- An inconsistency remains in Jira commentary for Order 1004 and cannot be independently resolved from current Snowflake runtime data.

RCA:
Documented Root Cause — Not Reproducible

Business Impact:
Documented; current runtime impact not quantifiable.

Resolution:
Aggregate payments to one row per ORDER_ID before joining to item-grain sales.

Validation:
Run fact-grain, reconciliation, split-payment and duplicate-detection regression tests once populated runtime data is available.
```

This is a **proposed** structure, not an automatically posted Jira comment.

---

# 47. Investigation Decision Tree

The Agent's reasoning can be summarized as:

```text
Is the issue documented in Jira?
          │
          ├── No → insufficient issue context
          │
          └── Yes
               ↓
       Is runtime data available?
               │
          ┌────┴────┐
          │         │
         No        Yes
          │         │
          ▼         ▼
       Block      Reproduce
       runtime       │
       validation    ▼
                 Validate grain
                      │
                      ▼
                  Validate join
                      │
                      ▼
                 Inspect GitHub
                      │
                      ▼
               Reconcile evidence
                      │
                      ▼
                 Classify RCA
```

If runtime data is unavailable, the Agent can still inspect implementation evidence but must stop short of claiming runtime validation.

---

# 48. Final FSP-8 Investigation Conclusion

The investigation establishes a coherent technical explanation for the documented FSP-8 issue:

```text
Item-grain sales
       +
Payment-grain records
       +
Direct ORDER_ID join
       ↓
Many-to-many multiplication
       ↓
Potential revenue duplication
```

The repository contains an implementation pattern intended to prevent that behavior:

```text
Payment aggregation by ORDER_ID
       ↓
One payment summary row/order
       ↓
Join to item-grain sales
```

However, the current Snowflake runtime does not contain populated:

```text
SALES
FACT_SALES
GOLD.VW_SALES_KPI
```

data.

Therefore:

> **The current environment does not independently reproduce or runtime-validate the FSP-8 issue/fix end-to-end.**

The strongest evidence-supported conclusion is:

```text
Documented Root Cause — Not Reproducible
```

with:

```text
Fix logic confirmed in transformation
```

but:

```text
Runtime behavior not yet validated
```

---

# 49. Engineering Takeaway

FSP-8 demonstrates why enterprise AI investigation should not be treated as simple question answering.

A credible investigation requires:

```text
Business context
      +
Data evidence
      +
Implementation evidence
      +
Grain analysis
      +
Conflict handling
      +
Evidence classification
      +
Runtime boundaries
      +
Regression testing
      +
Human governance
```

The Agent's value is therefore not merely that it can find the Jira issue or read SQL.

Its value is that it can connect those sources while preserving the distinction between:

```text
What someone reported
```

```text
What the code contains
```

and:

```text
What the current runtime actually proves
```

That distinction is the central engineering lesson of the FSP-8 case study.
