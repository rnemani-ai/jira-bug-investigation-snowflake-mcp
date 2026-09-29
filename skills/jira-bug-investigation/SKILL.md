---
name: jira-bug-investigation
description: Investigate Jira data-quality and analytics bugs using actual Snowflake evidence, classify findings by evidence strength, quantify impact only when supported by data, propose safe read-only resolution patterns and regression tests, and require explicit approval before any Jira write.
---

# Jira Bug Investigation

## Purpose

Use this skill for Jira bugs involving Snowflake data, data quality, analytics, reporting, finance, revenue, transformations, joins, pipelines, or downstream metrics.

The objective is to produce a rigorous, evidence-based root-cause analysis (RCA) and resolution proposal.

Always distinguish:

- Jira-reported facts
- Actual Snowflake observations
- Confirmed findings
- Documented but unverified claims
- Likely explanations
- Unverified hypotheses
- Illustrative examples
- Recommendations

Never fill missing evidence with assumptions merely to complete an RCA.

---

# 1. Mandatory Human Approval Gate

Jira updates require explicit user approval.

NEVER automatically:

- add an RCA comment
- modify Jira fields
- change status
- change priority
- change labels
- change description
- create or modify Jira issues
- post investigation results

Required workflow:

1. Investigate the Jira issue.
2. Investigate relevant Snowflake data.
3. Validate the reported behavior using actual data whenever possible.
4. Produce the RCA, evidence, business impact, resolution, regression tests, limitations, and sources.
5. Prepare the exact proposed Jira comment.
6. Show the complete proposed Jira comment.
7. State exactly: "This comment has NOT been posted to Jira."
8. Ask exactly: "Would you like me to post this comment to Jira?"
9. STOP.

Only after explicit approval may a Jira write tool be used.

These are NOT approval:

- "Looks good"
- "Okay"
- "Fine"
- "Thanks"
- "That works"

If the user requests changes, revise the comment and repeat the approval gate.

---

# 2. Evidence Integrity

## 2.1 Never invent evidence

Never invent:

- query results
- row counts
- revenue amounts
- percentages
- affected records
- business impact
- table contents
- Jira comments
- citations
- Snowflake observations
- production behavior

If required data is unavailable, say so.

## 2.2 Actual Snowflake data takes precedence

When Jira reports a specific row count, amount, or behavior and the corresponding Snowflake data exists:

1. Query Snowflake.
2. Compare the actual result with Jira.
3. Use the actual Snowflake result as evidence.
4. Explicitly identify discrepancies.

Do not blindly repeat Jira numbers.

## 2.3 Jira claims are not automatically confirmed

Treat statements such as:

- "Likely Cause"
- "Suspected Cause"
- "Expected Result"
- "Actual Result"

as Jira documentation unless independently validated.

For example:

"Jira reports that Order 1004 has 2 sales rows."

If BRONZE.SALES is empty, classify it as:

"Documented in Jira; not currently verifiable from Snowflake."

## 2.4 Empty or missing data blocks validation

If a required source table contains zero rows, or required data is unavailable:

- Do not simulate the missing data.
- Do not calculate measured business impact from assumptions.
- Do not claim the join was reproduced.
- Do not claim a fix was validated.
- Do not call the root cause confirmed solely from the Jira ticket.

Use:

**Documented / Consistent with Structure / Not Reproducible with Current Data**

and clearly state what cannot be validated.

## 2.5 Simulated data is never actual evidence

Synthetic examples may be used only to explain a mechanism.

If used, label them:

**Illustrative example — not actual Snowflake evidence.**

Never include simulated values in measured business-impact calculations.

---

# 3. Evidence Classification

For every important finding, use one of these classifications.

### Confirmed

Directly supported by actual Snowflake/Jira tool results.

### Documented

Reported by Jira but not independently validated.

### Likely

Supported by evidence but not completely proven.

### Unverified

Cannot currently be validated.

### Illustrative

An example used only to explain a mechanism.

Never describe an illustrative result as actual evidence.

---

# 4. Root Cause Classification

Use exactly one of these when appropriate.

### Confirmed Root Cause

Use ONLY when the causal behavior has been demonstrated with actual evidence.

### Documented Root Cause — Not Reproducible

Use when Jira documents the cause and available schema/evidence is consistent with it, but required runtime data is unavailable or empty.

### Likely Root Cause

Use when evidence strongly supports the explanation but direct causal demonstration is missing.

### Root Cause Not Yet Determined

Use when available evidence is insufficient.

Never upgrade a Jira "Likely Cause" to "Confirmed" without actual validation.

---

# 5. Business Impact Classification

Use exactly one of:

### Measured

Calculated directly from actual Snowflake data.

### Estimated

Derived from clearly stated assumptions. State the assumptions.

### Documented

Reported by Jira but not independently measured.

### Not Quantifiable with Current Data

Required data is unavailable or empty.

Never present documented or estimated impact as measured impact.

---

# 6. Step 1 — Retrieve and Understand Jira

Retrieve the requested Jira issue using Jira MCP.

Read, when available:

- Issue key
- Summary
- Description
- Expected result
- Actual result
- Steps to reproduce
- Affected Snowflake objects
- Likely/suspected cause
- Acceptance criteria
- Priority
- Labels
- Comments
- Linked issues

Create a clear separation between:

### Jira-reported facts

What Jira directly states.

### Jira hypotheses

Claims that require validation.

Do not treat a Jira "Likely Cause" as a confirmed root cause.

---

# 7. Step 2 — Identify Relevant Snowflake Objects

Identify every Snowflake object required for the investigation.

Use fully qualified names:

`DATABASE.SCHEMA.OBJECT`

For this project, examples include:

- `FINANCE_DEMO_DB.BRONZE.SALES`
- `FINANCE_DEMO_DB.BRONZE.PAYMENTS`
- `FINANCE_DEMO_DB.SILVER.FACT_SALES`
- `FINANCE_DEMO_DB.GOLD.VW_SALES_KPI`
- `FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW`

Do not claim an object was inspected unless it was actually queried or inspected.

---

# 8. Step 3 — Check Data Availability BEFORE Drawing Conclusions

Before performing RCA, check:

- object existence
- row count
- relevant columns
- relevant business keys
- relevant data range
- whether required data is populated

For each relevant object record:

- Object
- Row count
- Relevant schema
- Whether it can support validation

If a required source is empty, explicitly identify all validations that are blocked by that condition.

---

# 9. Step 4 — Determine Data Grain

Determine what one row represents in every relevant object.

Do not infer grain from the object name alone.

Examples:

- `BRONZE.SALES` → order-item grain
- `BRONZE.PAYMENTS` → payment-transaction grain
- `SILVER.FACT_SALES` → intended order-item grain
- `GOLD.VW_SALES_KPI` → reporting/aggregation grain

Support grain conclusions using schema and actual data when available.

Document the business key used to establish the grain.

---

# 10. Step 5 — Validate Joins and Transformations

For suspected join-related problems:

1. Query actual source data.
2. Determine matching records on each side.
3. Reproduce the reported join using actual tables.
4. Compare expected and actual joined rows.
5. Identify one-to-many or many-to-many multiplication.
6. Determine whether multiplication changes the reported metric.

Example:

If actual data contains:

- 2 sales rows for an order
- 3 successful payment rows

then a direct `ORDER_ID` join can produce:

`2 × 3 = 6`

joined rows.

But if SALES is empty, this is only a mechanism explanation, not an observed result.

Always distinguish:

- **Observed**
- **Inferred**
- **Illustrative**

---

# 11. Step 6 — Validate Business Metrics

Only quantify business impact when the underlying data supports it.

Potential metrics:

- Revenue
- Net sales
- Margin
- Order count
- Order-item count
- Payment count
- Duplicate rows

For every measured calculation provide:

- Source object
- Query purpose
- Observed result
- Calculation
- Interpretation

Never invent a dollar amount or percentage to make the RCA appear complete.

---

# 12. Step 7 — Never Invent Business Logic

This is mandatory.

Do NOT introduce:

- arbitrary constants
- placeholder percentages
- invented margin rates
- invented revenue formulas
- invented tax logic
- invented business rules

For example, NEVER create:

```sql
MARGIN_AMOUNT = SALES_AMOUNT * 0.30
```

unless 30% is an explicitly documented business rule.

If the existing business logic is unknown:

- Do not invent a replacement formula.
- Do not put an arbitrary placeholder formula into proposed deployment SQL.
- State that the existing business logic must be inspected/preserved.
- Keep the resolution focused on the verified defect.

---

# 13. Step 8 — Validate Proposed Fix vs. Schema

A schema change is NOT proof that a fix works.

If a table contains:

- `SUCCESSFUL_PAYMENT_COUNT`
- `SUCCESSFUL_PAYMENT_AMOUNT`
- `PAYMENT_METHODS`
- `PAYMENT_PATTERN`

that proves only that those columns exist.

It does NOT prove:

- transformation logic populates them correctly
- row multiplication is prevented
- revenue is correct
- margin is correct
- Gold metrics reconcile

Always distinguish:

1. Schema evidence
2. Transformation evidence
3. Runtime/data validation

If runtime data is unavailable, state that the fix remains unvalidated.

---

# 14. Step 9 — Grain-Safe Resolution

For a many-to-many join problem, the safe structural pattern is:

1. Aggregate the higher-cardinality source to the intended join grain.
2. Join only after grain alignment.
3. Preserve the intended fact-table grain.
4. Preserve existing business calculations.
5. Recalculate downstream metrics after correction.

Example read-only transformation pattern:

```sql
WITH payment_summary AS (
    SELECT
        ORDER_ID,
        COUNT(*) AS SUCCESSFUL_PAYMENT_COUNT,
        SUM(PAYMENT_AMOUNT) AS SUCCESSFUL_PAYMENT_AMOUNT,
        LISTAGG(DISTINCT PAYMENT_METHOD, ', ')
            WITHIN GROUP (ORDER BY PAYMENT_METHOD) AS PAYMENT_METHODS,
        CASE
            WHEN COUNT(*) > 1 THEN 'SPLIT_PAYMENT'
            ELSE 'SINGLE_PAYMENT'
        END AS PAYMENT_PATTERN
    FROM FINANCE_DEMO_DB.BRONZE.PAYMENTS
    WHERE PAYMENT_STATUS = 'SUCCESS'
    GROUP BY ORDER_ID
)
SELECT
    s.ORDER_ITEM_ID,
    s.ORDER_ID,
    s.ORDER_DATE,
    s.CUSTOMER_ID,
    s.PRODUCT_ID,
    s.SALES_CHANNEL,
    s.ORDER_STATUS,
    s.QUANTITY,
    s.UNIT_SELLING_PRICE,
    s.DISCOUNT_AMOUNT,
    s.TAX_AMOUNT,
    ps.SUCCESSFUL_PAYMENT_COUNT,
    ps.SUCCESSFUL_PAYMENT_AMOUNT,
    ps.PAYMENT_METHODS,
    ps.PAYMENT_PATTERN
FROM FINANCE_DEMO_DB.BRONZE.SALES s
LEFT JOIN payment_summary ps
    ON s.ORDER_ID = ps.ORDER_ID;
```

This is a structural/read-only pattern.

Do NOT invent revenue or margin formulas.

Do NOT replace existing business calculations unless their actual logic is known.

---

# 15. No Destructive or Data-Changing Resolution SQL

During investigation and proposed resolution:

Do NOT execute or propose as executable deployment instructions:

- `CREATE OR REPLACE`
- `CREATE`
- `ALTER`
- `DROP`
- `INSERT`
- `UPDATE`
- `DELETE`
- `MERGE`

unless the user explicitly requests an authorized implementation step.

When demonstrating the resolution, prefer a read-only `WITH ... SELECT` transformation pattern.

If deployment is required, state:

**Implementation/deployment is a separate authorized step after the RCA is approved.**

---

# 16. Regression Tests

Regression tests must be deterministic and based on the actual data model and business requirements.

## Test 1 — Fact Grain Integrity

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT ORDER_ITEM_ID) AS distinct_items,
    COUNT(*) - COUNT(DISTINCT ORDER_ITEM_ID) AS duplicate_rows
FROM FINANCE_DEMO_DB.SILVER.FACT_SALES;
```

Expected:

`duplicate_rows = 0`

## Test 2 — Duplicate Business Keys

```sql
SELECT
    ORDER_ITEM_ID,
    COUNT(*) AS occurrence_count
FROM FINANCE_DEMO_DB.SILVER.FACT_SALES
GROUP BY ORDER_ITEM_ID
HAVING COUNT(*) > 1;
```

Expected:

No rows.

## Test 3 — Split-Payment Row Preservation

When source data exists, compare the actual number of Bronze sales rows to the Silver fact rows at the same business grain.

Do NOT hard-code:

- "2 rows"
- "3 rows"

from Jira when Snowflake can determine the expected count.

Account for intentional filters in the transformation.

## Test 4 — Payment Pattern Classification

Verify:

- successful payment count > 1 → `SPLIT_PAYMENT`
- successful payment count = 1 → `SINGLE_PAYMENT`

Only execute when the relevant Silver data exists.

## Test 5 — Source-to-Target Reconciliation

Do NOT automatically assume:

`Bronze row count = Silver row count`

because Silver may intentionally filter or transform the population.

Only use row-count reconciliation when the transformation is known to preserve the same population.

Otherwise:

- identify the intended filter
- compare equivalent populations
- or mark reconciliation as blocked until the transformation logic is known

## Test 6 — Gold-to-Silver Reconciliation

Only perform when:

- both layers contain data
- metric definitions are equivalent
- populations/grain are aligned

If these conditions are not met, mark the test as blocked rather than producing a misleading PASS/FAIL.

---

# 17. Conflicting Evidence

When sources disagree:

1. Identify the conflict.
2. Do not silently choose one.
3. Determine whether actual Snowflake data can resolve it.
4. Prefer current queried data over stale/documented assumptions when applicable.
5. If data cannot resolve it, report the conflict as a limitation.

Example:

"Jira description reports 2 sales rows for Order 1004, while a previous Jira comment reports 3. BRONZE.SALES is currently empty, so the discrepancy cannot be resolved from Snowflake."

Never write:

"2 or 3 rows"

as a regression expectation.

---

# 18. Evidence and Citation Requirements

For every major factual conclusion provide:

- Source
- Query purpose
- Observed result
- Interpretation
- Evidence status

Use fully qualified Snowflake object names.

If native clickable citations or query references are available, preserve them.

If native citations are unavailable, provide the exact fully qualified object name.

Never fabricate citations.

---

# 19. Proposed Jira Comment Structure

Prepare the exact comment using:

## Root Cause Analysis

**Classification:** Confirmed Root Cause / Documented Root Cause — Not Reproducible / Likely Root Cause / Root Cause Not Yet Determined

State the evidence status.

## Evidence

For each evidence item:

- Source
- Query purpose
- Observed result
- Interpretation
- Evidence status

## Business Impact

State:

**Classification:** Measured / Estimated / Documented / Not Quantifiable with Current Data

Do not mix classifications.

## Resolution

Provide only a technically justified resolution.

Do not invent unknown business logic.

## Regression Tests

Provide deterministic tests appropriate to the actual model.

## Limitations

Explicitly identify:

- empty tables
- unavailable data
- conflicting evidence
- unknown transformation logic
- blocked validations

## Sources

List:

- Jira issue
- fully qualified Snowflake objects inspected

---

# 20. Mandatory Pre-Post Procedure

Before ANY Jira write operation:

1. Display the complete proposed Jira comment.
2. State exactly:

"This comment has NOT been posted to Jira."

3. Ask exactly:

"Would you like me to post this comment to Jira?"

4. STOP.

Do not call a Jira write tool before receiving explicit approval.

After explicit approval:

1. Post exactly the approved comment.
2. Do not alter the approved content unless requested.
3. Confirm that it was posted.
4. Do not make additional Jira changes unless separately authorized.

---

# 21. Investigation Permissions

Investigation should be read-only.

Prefer:

- `SELECT`
- `SHOW`
- `DESCRIBE`

Do not execute data-changing operations during investigation:

- `INSERT`
- `UPDATE`
- `DELETE`
- `MERGE`
- `CREATE`
- `CREATE OR REPLACE`
- `ALTER`
- `DROP`

unless the user explicitly requests and authorizes the operation.

Do not deploy a proposed fix automatically.

---

# 22. Final Investigation Response

Before approval, provide exactly:

1. Root Cause and classification
2. Evidence
3. Business Impact and classification
4. Resolution
5. Regression Tests
6. Limitations
7. Sources
8. Exact Proposed Jira Comment

Clearly distinguish:

- Confirmed findings
- Documented findings
- Likely findings
- Unverified hypotheses
- Illustrative examples
- Recommendations

The proposed Jira comment MUST be shown to the user before any Jira write operation.
