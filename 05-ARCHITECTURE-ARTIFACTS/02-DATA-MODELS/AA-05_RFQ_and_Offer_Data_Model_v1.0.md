# AA-05_RFQ_and_Offer_Data_Model_v1.0

# iKIA RFQ and Offer Data Model

## 1. Scope

This artifact defines the RFQ and Offer Data Model for the iKIA platform.

It supports buyer requirements, supplier offers, RFQ workflows, offer board, commercial negotiation, matching, award decisions, trust-based evaluation and contract generation.

---

## 2. Model Objectives

- Support structured RFQ creation.
- Support offer publication and offer board.
- Support multi-supplier responses.
- Support commodity-based matching.
- Support commercial negotiation.
- Support award decision management.
- Support contract generation.
- Support RFQ and offer analytics.
- Support AI recommendations.

---

## 3. Core RFQ Entities

### RFQ

Main request entity created by buyer.

Key attributes:

- RFQID
- BuyerID
- Status
- Priority
- SubmissionDate
- ClosingDate
- DeliveryRequiredDate
- Incoterm
- PaymentTerm
- CreatedAt

---

### RFQItem

Commodity line item requested in RFQ.

Key attributes:

- RFQItemID
- RFQID
- CommodityID
- Grade
- Quantity
- UnitOfMeasure
- SpecificationID

---

### RFQRequirement

Additional technical, commercial or logistics requirements.

---

### RFQAttachment

Documents attached to RFQ.

---

### RFQResponse

Supplier response to RFQ.

Key attributes:

- RFQResponseID
- RFQID
- SupplierID
- Status
- SubmittedAt
- ValidUntil

---

## 4. Core Offer Entities

### Offer

Main supplier offer entity.

Key attributes:

- OfferID
- SupplierID
- Status
- OfferType
- PublishedAt
- ValidUntil
- VisibilityScope

---

### OfferItem

Commodity line item offered by supplier.

Key attributes:

- OfferItemID
- OfferID
- CommodityID
- Grade
- Quantity
- UnitOfMeasure
- DeliveryLocation
- AvailableFrom

---

### OfferPrice

Pricing details for offer item.

---

### OfferValidity

Validity and expiry conditions.

---

### OfferAttachment

Documents attached to offer.

---

## 5. Commercial Negotiation Entities

### CommercialNegotiation

Negotiation record linked to RFQ or Offer.

---

### NegotiationRound

Each negotiation cycle.

---

### NegotiationMessage

Messages, comments and commercial discussions.

---

## 6. Matching Entities

### MatchingResult

Stores results of matching RFQs with offers and suppliers.

Matching dimensions:

- Commodity match
- Specification match
- Quantity match
- Location match
- Delivery date match
- Trust score
- Price competitiveness
- Compliance status

---

## 7. Award Entities

### AwardDecision

Final decision to award RFQ to supplier or offer.

---

### AwardEvaluation

Evaluation score and comparison.

---

## 8. Commercial Terms

### CommercialTerm

General commercial terms.

### PaymentTerm

Payment structure.

### DeliveryTerm

Delivery and Incoterm conditions.

---

## 9. Workflow and Audit

### RFQWorkflow

Lifecycle workflow of RFQ.

### OfferWorkflow

Lifecycle workflow of Offer.

### RFQAudit

Audit history of RFQ.

### OfferAudit

Audit history of Offer.

---

## 10. Key Relationships

- Buyer creates RFQs.
- RFQ contains many RFQItems.
- RFQItem references Commodity.
- RFQ has many RFQRequirements.
- RFQ has many RFQAttachments.
- Supplier submits RFQResponses.
- Supplier publishes Offers.
- Offer contains many OfferItems.
- OfferItem references Commodity.
- OfferItem has OfferPrice.
- RFQ and Offer may be matched through MatchingResult.
- RFQResponse may enter CommercialNegotiation.
- Negotiation has many NegotiationRounds.
- NegotiationRound has many NegotiationMessages.
- RFQ may result in AwardDecision.
- AwardDecision may trigger Contract generation.
- RFQ and Offer both have Workflow and Audit history.

---

## 11. RFQ Lifecycle

```text
Draft
↓
Submitted
↓
Published
↓
Supplier Invited
↓
Response Received
↓
Evaluation
↓
Negotiation
↓
Awarded
↓
Contracted
↓
Closed

12. Offer Lifecycle
Draft
↓
Submitted
↓
Validated
↓
Published
↓
Interested Buyer
↓
Negotiation
↓
Accepted
↓
Contracted
↓
Expired / Closed

13. AI Readiness
This model supports:
•	RFQ completeness checking
•	Supplier recommendation
•	Offer recommendation
•	Price comparison
•	Negotiation support
•	Award recommendation
•	Risk detection
•	Commercial opportunity detection
 
14. Trust and Compliance Integration
Matching must consider:
•	Supplier Trust Score
•	Buyer Trust Level
•	Compliance Status
•	Sanctions Screening
•	Document Completeness
•	Past Performance
•	Claims History
 
15. Analytics Readiness
This model supports:
•	RFQ Conversion Rate
•	Offer Acceptance Rate
•	Supplier Response Rate
•	Average Negotiation Time
•	Award Rate
•	Contract Conversion Rate
•	GMV Pipeline
 
16. Future Physical Mapping
This model will be mapped to:
•	PostgreSQL tables
•	Supabase tables
•	RFQ APIs
•	Offer APIs
•	Matching Engine
•	Contract Engine
•	Analytics Mart
•	Trade Knowledge Graph
 
End of Artifact

