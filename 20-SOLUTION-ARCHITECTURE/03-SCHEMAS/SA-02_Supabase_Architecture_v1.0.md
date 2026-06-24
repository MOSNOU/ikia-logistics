# SA-02_Supabase_Architecture_v1.0

# iKIA Supabase Architecture

Version: 1.0

Status: Target Architecture

---

# 1. Purpose

This document defines the target Supabase architecture for the iKIA Logistics Platform.

It provides the blueprint for:

- PostgreSQL Design
- Authentication
- Authorization
- Row Level Security
- Storage
- Realtime
- Edge Functions
- Audit Logging
- AI Readiness
- GraphRAG Readiness

---

# 2. Platform Components

Supabase Components:

- PostgreSQL
- Supabase Auth
- Storage
- Realtime
- Edge Functions
- Database Functions
- Cron Jobs
- pgvector
- Monitoring

---

# 3. PostgreSQL Schema Architecture

The platform uses schema-based domain separation.

## Core Schemas

identity

organization

supplier

commodity

rfq

offer

contract

logistics

finance

trust

compliance

document

workflow

knowledge

analytics

integration

audit

---

# 4. Multi-Tenant Architecture

Hierarchy:

Tenant
↓
Organization
↓
Business Unit
↓
User
↓
Transaction

All transactional tables must include:

- tenant_id
- organization_id
- created_by
- created_at
- updated_at

---

# 5. Authentication Architecture

Provider:

Supabase Auth

Supported Methods:

- Email / Password
- Magic Link
- OTP
- SSO (Future)
- Enterprise Federation (Future)

Core Entities:

- User
- Session
- Identity
- MFA

---

# 6. Authorization Architecture

Authorization Model:

RBAC + RLS

Roles:

- PlatformAdmin
- OrganizationAdmin
- SupplierAdmin
- BuyerAdmin
- CarrierAdmin
- ComplianceOfficer
- FinanceOfficer
- OperationsUser
- ReadOnlyUser

---

# 7. Row Level Security Strategy

All business tables protected by RLS.

Policy Dimensions:

- Tenant
- Organization
- Role
- Ownership
- Delegation

Example:

Users may only access records where:

organization_id = current_user.organization_id

---

# 8. Organization Model

Organization Types:

- Buyer
- Supplier
- Carrier
- Broker
- Government
- Platform

Key Tables:

organization.organization
organization.membership
organization.business_unit

---

# 9. Storage Architecture

Storage Buckets:

supplier-documents

commodity-documents

contracts

logistics-documents

compliance-documents

knowledge-assets

public-assets

system-assets

---

# 10. File Security Model

Files protected by:

- Bucket Policies
- RLS Policies
- Signed URLs
- Expiring URLs

Public files stored separately.

---

# 11. Realtime Architecture

Realtime enabled for:

- RFQ Updates
- Offer Updates
- Contract Updates
- Shipment Tracking
- Notifications
- Chat
- Workflow Status

Realtime Channels:

rfq

offer

contract

shipment

notification

workflow

---

# 12. Edge Functions Architecture

Responsibilities:

- External Integrations
- Webhooks
- Scheduled Jobs
- AI Processing
- File Processing
- Compliance Processing

Examples:

create-rfq

publish-offer

generate-contract

shipment-update

knowledge-ingestion

ai-assistant

---

# 13. Database Functions

Core Functions:

- Trust Score Calculation
- RFQ Matching
- Supplier Ranking
- ETA Calculation
- Risk Scoring
- Compliance Validation

---

# 14. Cron Jobs

Scheduled Processes:

- Expired RFQs
- Expired Offers
- Contract Monitoring
- Shipment Monitoring
- Escrow Monitoring
- Compliance Review
- Knowledge Refresh

---

# 15. Audit Architecture

Audit Tables:

audit.audit_event

audit.audit_entity

audit.audit_access

Tracked Events:

- Create
- Update
- Delete
- Approval
- Login
- Signature
- Settlement

---

# 16. AI Readiness

Database supports:

- Knowledge Chunks
- Embeddings
- AI Context
- Prompt Templates
- Agent Memory

---

# 17. pgvector Architecture

Vector Store Tables:

knowledge.embedding

knowledge.chunk

knowledge.source

Capabilities:

- Semantic Search
- RAG
- GraphRAG
- Similarity Search

---

# 18. Performance Strategy

Indexes:

- Primary Keys
- Foreign Keys
- Composite Indexes
- Full Text Search
- Vector Indexes

Partitioning:

- Audit Data
- Tracking Events
- Analytics Data

---

# 19. Backup Strategy

Daily Backup

Point In Time Recovery

Cross Region Backup

Monthly Archive

Quarterly Recovery Test

---

# 20. Monitoring Strategy

Database Monitoring

Query Monitoring

Storage Monitoring

Realtime Monitoring

Edge Function Monitoring

Security Monitoring

---

# 21. Disaster Recovery

Recovery Objectives:

RPO < 15 Minutes

RTO < 1 Hour

Automated Recovery Procedures

---

# 22. Future Mapping

This architecture directly supports:

- Claude Code Development
- Database Build
- Migration Scripts
- RLS Policies
- Edge Functions
- Storage Buckets
- AI Platform
- Knowledge Graph

---

**End of Artifact**

SA-02_Supabase_Architecture_v1.0