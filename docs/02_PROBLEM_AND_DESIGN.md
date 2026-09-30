# Problem, Requirements & Design

## Business problem

FSP-8 reports revenue duplication for orders using multiple successful
payment methods.

The representative issue describes item-grain sales joined directly to
payment-grain data on `ORDER_ID`, creating a many-to-many risk.

## Technical requirements

The investigation must: - retrieve Jira context; - inspect Snowflake
objects and runtime availability; - identify data grain; - inspect
GitHub transformation code; - compare documented claims with
implementation and runtime evidence; - surface conflicting evidence; -
classify RCA and business impact; - avoid fabricated results; - use
read-only investigation; - require human approval before Jira writes.

## Key design decisions

### Evidence-first

Every conclusion is tied to a source and evidence category.

### Grain-aware

Sales are treated at `ORDER_ITEM_ID` grain; payments at `PAYMENT_ID`
grain.

### Runtime boundary

Empty data blocks runtime reproduction.

### Code/runtime separation

Finding a correct SQL transformation in GitHub does not prove the
deployed runtime is executing it.

### Human-in-the-loop

Jira updates are proposed first and require explicit approval.

### Cost-aware POC

Small datasets, focused queries and warehouse auto-suspend reduce
unnecessary Snowflake trial consumption.

## Deliberate non-goals

The current POC does not implement RAG/vector search, embeddings,
LangChain, multi-agent orchestration, dbt, ServiceNow, Slack/Teams,
Confluence evidence integration or automatic Jira posting.
