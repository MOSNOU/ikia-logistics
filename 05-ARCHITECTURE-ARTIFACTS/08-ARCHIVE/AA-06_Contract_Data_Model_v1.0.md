# AA-06_Contract_Data_Model_v1.0

# iKIA Contract Data Model

## 1. Scope

This artifact defines the Contract Data Model for the iKIA platform.

It supports contract lifecycle management, template-based contract generation, negotiation, approvals, digital signatures, immutable snapshots, obligations, commitments, amendments, escrow, settlement, auditability and contract knowledge graph.

---

## 2. Model Objectives

- Support full Contract Lifecycle Management.
- Support AI-assisted contract drafting.
- Support contract templates and clauses.
- Support version control and immutable snapshots.
- Support digital signature and counterparty approval.
- Support obligations, commitments and milestones.
- Support amendments and change history.
- Support escrow and settlement integration.
- Support contract audit and compliance.
- Support contract analytics and knowledge graph.

---

## 3. Core Contract Entities

### Contract

Main contract entity.

Key attributes:

- ContractID
- ContractNumber
- ContractType
- Status
- EffectiveDate
- ExpiryDate
- ContractValue
- Currency
- CreatedAt

---

### ContractVersion

Stores different versions of a contract.

Key attributes:

- ContractVersionID
- ContractID
- VersionNumber
- VersionStatus
- CreatedBy
- CreatedAt

---

### ContractTemplate

Reusable contract template.

---

### ContractClause

Reusable or contract-specific clauses.

---

### ContractParty

Parties involved in contract.

Examples:

- Buyer
- Supplier
- Carrier
- Broker
- Guarantor
- Platform

---

### ContractRole

Defines role of each party.

---

### ContractItem

Commercial item linked to commodity, RFQ or offer.

---

### ContractTerm

General contractual terms.

Examples:

- Incoterm
- Payment Term
- Delivery Term
- Warranty
- Force Majeure

---

### ContractPricing

Pricing and commercial value records.

---

## 4. Obligation and Commitment Entities

### ContractObligation

Obligations created by contract.

Examples:

- Deliver commodity
- Pay invoice
- Provide documents
- Arrange shipment
- Maintain insurance

---

### ContractMilestone

Important contract milestones.

Examples:

- Advance Payment
- Loading Date
- Delivery Date
- Inspection Date
- Final Settlement

---

### ContractCommitment

Specific commitments made by parties.

---

## 5. Approval and Signature Entities

### ContractApproval

Approval records.

---

### ContractWorkflow

Workflow execution records.

---

### ContractSignature

Signature record per party.

---

### DigitalSignature

Digital signature evidence.

---

## 6. Amendment and Snapshot Entities

### ContractAmendment

Formal amendment to contract.

---

### ContractSnapshot

Immutable snapshot at important lifecycle moments.

Examples:

- Pre-Signature Snapshot
- Signed Snapshot
- Amendment Snapshot
- Closing Snapshot

---

## 7. Document and Audit Entities

### ContractDocument

Documents related to contract.

---

### ContractAttachment

Attachments.

---

### ContractAudit

Audit history.

---

## 8. Risk and Compliance Entities

### ContractRisk

Contract risk records.

---

### ContractCompliance

Compliance checks.

---

## 9. Financial Integration Entities

### EscrowCase

Escrow record linked to contract.

---

### Invoice

Invoice generated from contract.

---

### Payment

Payment linked to invoice or settlement.

---

### Settlement

Settlement linked to contract and delivery.

---

## 10. Knowledge Graph Entity

### ContractKnowledgeNode

Semantic representation of contract for AI and knowledge graph.

---

## 11. Key Relationships

- Contract may be generated from RFQ or AwardDecision.
- Contract has many ContractVersions.
- ContractVersion may be based on ContractTemplate.
- Contract has many ContractParties.
- ContractParty has ContractRole.
- Contract has many ContractItems.
- ContractItem references Commodity.
- Contract has many ContractTerms.
- Contract has many ContractPricing records.
- Contract has many Obligations.
- Contract has many Milestones.
- Contract has many Commitments.
- Contract has many Approvals.
- Contract has Workflow records.
- Contract has many Signatures.
- ContractSignature may have DigitalSignature evidence.
- Contract has many Amendments.
- Contract has immutable Snapshots.
- Contract has many Documents and Attachments.
- Contract has Audit history.
- Contract may create EscrowCase.
- Contract may create Invoice, Payment and Settlement records.
- Contract may have Risk and Compliance records.
- Contract may be represented in Knowledge Graph.

---

## 12. Contract Lifecycle

```text
Draft
↓
Review
↓
Negotiation
↓
Approval
↓
Signature
↓
Activation
↓
Execution
↓
Amendment / Monitoring
↓
Settlement
↓
Closure