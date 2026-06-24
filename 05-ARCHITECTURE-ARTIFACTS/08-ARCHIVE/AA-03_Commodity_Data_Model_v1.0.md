# AA-03_Commodity_Data_Model_v1.0

# iKIA Commodity Data Model

## 1. Scope

This artifact defines the Commodity Data Model for the iKIA platform.

It supports commodity cataloging, product classification, supplier capabilities, offer board, RFQ matching, contract generation, compliance, logistics, analytics and AI knowledge graph.

---

## 2. Commodity Data Model Objectives

- Standardize all commodity records.
- Support multi-level commodity taxonomy.
- Support HS Code, UN Code and CAS Number mapping.
- Support MSDS, TDS and Product Datasheet management.
- Support AI-based commodity classification.
- Support supplier-offer-RFQ-contract relationships.
- Support commodity analytics and market intelligence.

---

## 3. Core Commodity Entities

### CommodityCategory

Top-level classification.

Examples:

- Energy
- Petrochemical
- Chemical
- Metals
- Mining
- Agriculture
- Construction Materials
- Industrial Equipment

---

### CommodityFamily

Second-level grouping inside a category.

Examples:

- Bitumen
- Methanol
- Urea
- LPG
- Polyethylene
- Copper Cathode
- Iron Ore

---

### CommodityGroup

Operational grouping for similar products.

---

### Commodity

Main product master entity.

Key attributes:

- CommodityID
- CommodityName
- CategoryID
- FamilyID
- GroupID
- Status
- TrustLevel
- CreatedAt

---

### CommodityGrade

Defines grade, quality or commercial variation.

Examples:

- Bitumen 60/70
- Bitumen 80/100
- Methanol AA Grade
- Urea Granular
- Urea Prilled

---

### CommoditySpecification

Defines technical specification set for a commodity or grade.

---

### CommodityAttribute

Defines reusable technical attribute.

Examples:

- Density
- Viscosity
- Flash Point
- Sulfur Content
- Moisture
- Purity
- Particle Size

---

### CommodityProperty

Stores actual value of attributes for a specification.

---

### CommodityPackaging

Defines packaging options.

Examples:

- Bulk
- Drum
- Jumbo Bag
- IBC
- Flexitank
- Container
- Tanker

---

### CommodityUnit

Defines allowed units of measure.

Examples:

- MT
- KG
- Liter
- Cubic Meter
- Barrel
- Piece

---

## 4. Compliance and Coding Entities

### CommodityHSCode

Maps commodity to HS Code.

### CommodityUNCode

Maps dangerous goods to UN code.

### CommodityCASNumber

Maps chemical products to CAS Number.

### CommodityAlias

Stores alternate names, trade names and multilingual names.

---

## 5. Document Entities

### CommodityDocument

General document repository for commodity.

### CommodityMSDS

Material Safety Data Sheet record.

### CommodityTDS

Technical Data Sheet record.

### CommodityCertificate

Certificates linked to commodity.

### CommodityImage

Images and visual assets.

---

## 6. Market Data Entities

### CommodityMarketData

Stores market signals, demand, supply and price indicators.

### CommodityPriceIndex

Stores historical and current price indexes.

---

## 7. Key Relationships

- CommodityCategory contains many CommodityFamilies.
- CommodityFamily contains many CommodityGroups.
- CommodityGroup contains many Commodities.
- Commodity has many CommodityGrades.
- CommodityGrade has many CommoditySpecifications.
- CommoditySpecification has many CommodityProperties.
- CommodityProperty references CommodityAttribute.
- Commodity has many Packaging options.
- Commodity has many HS Codes.
- Commodity may have UN Codes.
- Commodity may have CAS Numbers.
- Commodity has many Documents.
- Commodity may have MSDS and TDS records.
- Commodity may have Market Data and Price Index records.
- Supplier capabilities reference Commodity.
- Offer items reference Commodity.
- RFQ items reference Commodity.
- Contract items reference Commodity.
- Knowledge Graph nodes reference Commodity.

---

## 8. Commodity Coding Strategy

Recommended internal code format:

```text
IKIA-COM-[CATEGORY]-[FAMILY]-[PRODUCT]-[GRADE]-[VERSION]

Example:
IKIA-COM-PET-BIT-6070-V01

9. AI Readiness
The commodity model must support:
•	AI classification
•	Similar product detection
•	HS Code suggestion
•	MSDS/TDS draft generation
•	Product datasheet generation
•	Semantic commodity search
•	Commodity knowledge graph
•	Market signal matching
 
10. Data Governance
Each commodity record must have:
•	Commodity Data Owner
•	Commodity Data Steward
•	Approval Status
•	Version History
•	Audit Trail
•	Source Record
•	Trust Level
 
11. Future Physical Mapping
This model will be mapped to:
•	PostgreSQL tables
•	Supabase tables
•	API endpoints
•	Search indexes
•	Vector database
•	Knowledge graph nodes
•	Analytics data mart
 
End of Artifact
AA-03_Commodity_Data_Model_v1.0

