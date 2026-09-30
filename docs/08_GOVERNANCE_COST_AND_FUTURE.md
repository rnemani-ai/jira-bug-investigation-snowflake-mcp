# Governance, Cost Controls and Future Extensions

## Governance

The investigation role is `FINANCE_AGENT_ROLE` with least-privilege
access to the relevant Snowflake environment.

Investigation is read-only: SELECT/SHOW/DESCRIBE style operations are
used rather than data-changing SQL.

External integrations use OAuth/GitHub App mechanisms rather than
embedding user credentials in prompts.

## Jira write governance

The Agent never silently posts an investigation result. It shows the
exact proposed comment and requires human approval.

## Evidence governance

The system explicitly distinguishes confirmed evidence from documented
claims, likely interpretations, unverified statements, illustrative
data, blocked validation and conflicts.

## Cost controls

Because this is a Snowflake trial environment: - datasets remain
small; - queries are focused; - unnecessary full-corpus processing is
avoided; - warehouse auto-suspend is used; - lightweight evaluation is
preferred before larger native evaluation.

## Current limitations

-   Runtime reproduction of FSP-8 is blocked by empty relevant Snowflake
    tables.
-   Repository code evidence does not prove production
    deployment/runtime execution.
-   Six representative evaluations were executed; four optional cases
    remain.
-   Jira posting remains behind human approval.

## Not implemented

-   dbt integration
-   ServiceNow
-   Slack/Teams
-   Confluence as an evidence source
-   RAG/vector database
-   embeddings/LangChain
-   multi-agent orchestration
-   automatic Jira posting
-   dedicated production audit platform

## Future extensions

dbt is a particularly natural next step because model metadata, lineage,
tests and run status could add another evidence layer:

`Jira → GitHub → dbt → Snowflake runtime`

Other integrations should be added only when they contribute a distinct
evidence or workflow capability.
