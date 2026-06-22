# SA-08_Environment_Architecture_v1.0

# iKIA Environment Architecture

Version: 1.0

Status: Target Architecture

---

# 1. Purpose

This document defines the environment architecture for the iKIA Logistics Platform.

It establishes the official environment strategy for development, testing, UAT, staging and production.

---

# 2. Environment Principles

- Environment Separation
- Production Protection
- Secure Secrets
- Controlled Promotion
- Data Isolation
- Repeatable Deployment
- Observable Environments
- Recovery Readiness

---

# 3. Official Environments

## ENV-01 Local

Developer machine environment.

Purpose:

- Feature development
- Local testing
- Supabase CLI usage
- Local migrations

---

## ENV-02 Development

Shared development environment.

Purpose:

- Feature integration
- Developer testing
- Early QA

---

## ENV-03 Testing

Quality assurance environment.

Purpose:

- Automated testing
- Regression testing
- Integration testing

---

## ENV-04 UAT

User Acceptance Testing environment.

Purpose:

- Business validation
- Stakeholder review
- Process validation

---

## ENV-05 Staging

Production-like environment.

Purpose:

- Final release validation
- Security validation
- Performance validation
- Migration rehearsal

---

## ENV-06 Production

Live operational environment.

Purpose:

- Real users
- Real data
- Real transactions
- Production operations

---

# 4. Supabase Environment Separation

Recommended setup:

- Supabase Local
- Supabase Development Project
- Supabase Testing Project
- Supabase UAT Project
- Supabase Staging Project
- Supabase Production Project

Each project must have separate:

- Database
- Auth configuration
- Storage buckets
- Edge functions
- Secrets
- RLS policies
- Realtime configuration

---

# 5. Vercel Environment Separation

Recommended setup:

- Local
- Preview
- Development
- Testing
- UAT
- Staging
- Production

Each environment must have separate:

- Environment variables
- Supabase URL
- Supabase anon key
- Feature flags
- API base URL
- Monitoring configuration

---

# 6. Data Management Strategy

## Local

Synthetic data only.

## Development

Synthetic and demo data.

## Testing

Controlled test data.

## UAT

Business-approved test data.

## Staging

Production-like masked data.

## Production

Real production data.

---

# 7. Test Data Strategy

Test data must support:

- Supplier onboarding
- Commodity management
- RFQ lifecycle
- Offer publication
- Contract lifecycle
- Shipment tracking
- Escrow workflow
- AI knowledge ingestion

---

# 8. Production Data Protection

Rules:

- No direct production data in local.
- No unmasked production data in development.
- Production access restricted.
- Export requires approval.
- All access is audited.

---

# 9. Secrets Management

Each environment must have separate secrets.

Secret categories:

- Supabase keys
- OpenAI keys
- Webhook secrets
- Payment provider keys
- Integration tokens
- Email/SMS keys

Rules:

- No secrets in code.
- No sharing across environments.
- Rotation policy required.
- Production secrets require restricted access.

---

# 10. Access Control

Access levels:

| Environment | Access |
|---|---|
| Local | Developer |
| Development | Developers |
| Testing | QA + Developers |
| UAT | Business + QA |
| Staging | Release Team |
| Production | Restricted Ops |

---

# 11. Environment Promotion Workflow

```text
Local
↓
Development
↓
Testing
↓
UAT
↓
Staging
↓
Production