# AA-01_Enterprise_ERD_v1.0

# Enterprise ERD for iKIA Platform

## 1. Scope

This artifact defines the enterprise-level Entity Relationship Model for the iKIA Logistics, Supply Chain and Trade Platform.

It covers the core domains required for CRM, Supplier Management, Commodity Management, Offer Board, RFQ, Contract, Logistics, Shipment, Settlement, Trust, Compliance, Workflow, Document Management, AI Knowledge and Analytics.

## 2. Enterprise Data Domains

1. Identity & Access
2. Organization
3. Customer
4. Supplier
5. Commodity
6. Offer
7. RFQ
8. Contract
9. Logistics
10. Carrier
11. Shipment
12. Finance
13. Escrow
14. Trust
15. Compliance
16. Document
17. Workflow
18. AI & Knowledge

## 3. Core Entities

### Identity & Access
- User
- Role
- Permission
- UserRole
- RolePermission

### Organization
- Organization
- Branch
- Contact

### Customer
- Customer
- CustomerProfile

### Supplier
- Supplier
- SupplierCapability
- SupplierCertificate

### Commodity
- Commodity
- CommodityCategory
- CommodityFamily
- CommoditySpecification
- ProductCode

### Offer
- Offer
- OfferItem

### RFQ
- RFQ
- RFQItem
- RFQResponse

### Contract
- Contract
- ContractParty
- ContractObligation

### Logistics & Shipment
- LogisticsOrder
- TransportPlan
- Carrier
- Vehicle
- Driver
- Shipment
- ShipmentItem
- TrackingEvent
- ProofOfDelivery

### Finance
- Invoice
- Payment
- Settlement
- EscrowCase

### Trust & Compliance
- TrustProfile
- TrustScore
- ComplianceCase
- VerificationRecord

### Document & Workflow
- Document
- DocumentVersion
- WorkflowInstance
- WorkflowTask

### AI & Knowledge
- KnowledgeAsset
- KnowledgeChunk
- VectorEmbedding
- AIInteraction

## 4. Key Relationships

- Organization has many Users.
- Organization has many Branches.
- Organization may be Customer, Supplier, Carrier or Partner.
- Supplier publishes Offers.
- Offer contains OfferItems.
- Commodity is referenced by OfferItems and RFQItems.
- Customer creates RFQs.
- RFQ contains RFQItems.
- Supplier submits RFQResponses.
- RFQ may result in Contract.
- Contract has ContractParties and ContractObligations.
- Contract may create LogisticsOrder.
- LogisticsOrder creates TransportPlan.
- TransportPlan assigns Carrier, Vehicle and Driver.
- Shipment executes LogisticsOrder.
- Shipment has TrackingEvents and ProofOfDelivery.
- Delivered Shipment triggers Invoice and Settlement.
- EscrowCase may be linked to Contract or Settlement.
- TrustProfile is linked to Organization.
- ComplianceCase may be linked to Organization, Supplier, Contract or Shipment.
- Document can be attached to any core business entity.
- WorkflowInstance can manage approval and lifecycle of any major entity.
- KnowledgeAsset, KnowledgeChunk and VectorEmbedding support AI, RAG and semantic search.

## 5. Aggregate Boundaries

### Customer Aggregate
Customer, CustomerProfile, Contact

### Supplier Aggregate
Supplier, SupplierCapability, SupplierCertificate

### Commodity Aggregate
Commodity, CommodityCategory, CommodityFamily, CommoditySpecification, ProductCode

### Offer Aggregate
Offer, OfferItem

### RFQ Aggregate
RFQ, RFQItem, RFQResponse

### Contract Aggregate
Contract, ContractParty, ContractObligation

### Shipment Aggregate
Shipment, ShipmentItem, TrackingEvent, ProofOfDelivery

### Finance Aggregate
Invoice, Payment, Settlement, EscrowCase

### Trust Aggregate
TrustProfile, TrustScore, VerificationRecord

### Knowledge Aggregate
KnowledgeAsset, KnowledgeChunk, VectorEmbedding, AIInteraction

## 6. Future Physical Mapping

This ERD will be mapped later to:

- PostgreSQL schema
- Supabase tables
- Row Level Security policies
- API endpoints
- Prisma or ORM models
- Knowledge Graph model
- Analytics warehouse model

**End of Artifact**

AA-01_Enterprise_ERD_v1.0