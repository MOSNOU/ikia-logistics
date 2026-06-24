# AA-04_Supplier_Data_Model_v1.0

# iKIA Supplier Data Model

## 1. Scope

This artifact defines the Supplier Data Model for the iKIA platform.

It supports supplier onboarding, KYB, trust scoring, compliance, commodity mapping, offer board, RFQ matching, contract management, supplier analytics and supplier knowledge graph.

---

## 2. Supplier Data Model Objectives

- Create a reliable Supplier Registry.
- Support supplier onboarding and verification.
- Support KYB and compliance controls.
- Link suppliers to commodities and capabilities.
- Support supplier trust scoring.
- Support supplier performance monitoring.
- Support offer and RFQ matching.
- Support supplier analytics and AI intelligence.

---

## 3. Core Supplier Entities

### Supplier

Main supplier master entity.

Key attributes:

- SupplierID
- OrganizationID
- SupplierType
- Status
- ApprovalStatus
- TrustLevel
- CreatedAt

---

### SupplierProfile

Extended profile of supplier.

Key attributes:

- LegalName
- CommercialName
- RegistrationNumber
- TaxID
- Country
- Website
- CompanyDescription

---

### SupplierCapability

Defines operational and commercial capabilities.

Examples:

- Commodity Supply
- Export Capability
- Domestic Delivery
- Bulk Supply
- Packaging Capability
- Monthly Capacity

---

### SupplierCommodity

Maps supplier to commodities they can supply.

Key attributes:

- SupplierID
- CommodityID
- Grade
- Capacity
- MinimumOrderQuantity
- SupplyRegion

---

### SupplierCertificate

Certificates and quality documents.

Examples:

- ISO
- Quality Certificate
- Product Certificate
- Export License
- Inspection Certificate

---

### SupplierLicense

Legal and operational licenses.

---

### SupplierComplianceRecord

Compliance checks and status.

Examples:

- KYB Status
- Sanctions Screening
- Trade Compliance
- Tax Compliance
- Regulatory Review

---

### SupplierTrustProfile

Supplier trust profile linked to Trust Engine.

---

### SupplierTrustScore

Historical trust scores.

---

### SupplierPerformance

Performance history.

Metrics:

- RFQ Response Time
- Offer Acceptance Rate
- Delivery Success Rate
- Claim Rate
- Contract Success Rate

---

### SupplierLocation

Supplier locations.

Examples:

- Head Office
- Factory
- Warehouse
- Loading Point

---

### SupplierContact

Supplier contacts.

---

### SupplierBankAccount

Supplier banking details.

Sensitive and restricted.

---

### SupplierDocument

Supplier document repository.

---

### SupplierInsurance

Insurance information.

---

### SupplierAudit

Audit and inspection records.

---

### SupplierRiskAssessment

Supplier risk profile.

---

### SupplierRating

Ratings from buyers, platform and operations.

---

### SupplierRelationship

Commercial relationship records.

---

### SupplierApproval

Approval workflow status and history.

---

## 4. Key Relationships

- Supplier is based on Organization.
- Supplier has one SupplierProfile.
- Supplier has many SupplierCapabilities.
- Supplier supplies many Commodities through SupplierCommodity.
- Supplier has many Certificates.
- Supplier has many Licenses.
- Supplier has many Compliance Records.
- Supplier has one Trust Profile.
- Supplier has many Trust Scores.
- Supplier has many Performance Records.
- Supplier has many Locations.
- Supplier has many Contacts.
- Supplier may have many Bank Accounts.
- Supplier has many Documents.
- Supplier may have Insurance Records.
- Supplier may have Audit Records.
- Supplier may have Risk Assessments.
- Supplier may have Ratings.
- Supplier participates in Relationships.
- Supplier has Approval History.

---

## 5. Supplier Onboarding Lifecycle

```text
Registration
↓
Profile Completion
↓
Document Submission
↓
KYB Review
↓
Compliance Screening
↓
Trust Assessment
↓
Approval
↓
Activation

6. Supplier Trust Integration

Supplier Trust is calculated from:

* Verification status
* Compliance status
* Document completeness
* Transaction history
* Performance records
* Buyer feedback
* Risk assessments
* Claims history

⸻

7. Supplier Compliance Integration

Supplier Compliance includes:

* KYB verification
* Sanctions screening
* Tax validation
* Regulatory status
* Export/import eligibility
* Document validity

⸻

8. Supplier Commodity Mapping

SupplierCommodity is a core bridge entity.

It connects:
Supplier
↓
Commodity
↓
Grade
↓
Capacity
↓
Region
↓
Offer / RFQ Matching

9. AI Readiness

This model supports:

* Supplier profile summarization
* Supplier risk detection
* Supplier capability matching
* RFQ supplier recommendation
* Supplier trust explanation
* Supplier knowledge graph
* Supplier performance prediction

⸻

10. Data Governance

Each supplier record must have:

* Supplier Data Owner
* Supplier Data Steward
* Approval Status
* KYB Status
* Compliance Status
* Trust Status
* Version History
* Audit Trail

⸻

11. Future Physical Mapping

This model will be mapped to:

* PostgreSQL tables
* Supabase tables
* Supplier APIs
* Trust Engine
* Compliance Engine
* RFQ Matching Engine
* Knowledge Graph
* Supplier Analytics Mart

⸻

End of Artifact