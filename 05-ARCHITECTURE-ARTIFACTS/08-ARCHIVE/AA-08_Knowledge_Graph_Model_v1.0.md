# AA-08_Knowledge_Graph_Model_v1.0

# iKIA Knowledge Graph Model

## 1. Scope

This artifact defines the Enterprise Knowledge Graph Model for the iKIA platform.

It supports AI Copilot, GraphRAG, semantic search, relationship discovery, recommendation engine, commodity intelligence, supplier intelligence, trade intelligence, logistics intelligence and corridor intelligence.

---

## 2. Graph Domains

- Enterprise Knowledge Graph
- Commodity Knowledge Graph
- Supplier Knowledge Graph
- Trade Knowledge Graph
- Contract Knowledge Graph
- Logistics Knowledge Graph
- Corridor Knowledge Graph
- Compliance Knowledge Graph
- Market Intelligence Graph

---

## 3. Core Nodes

### Organization
Represents companies, institutions, buyers, suppliers, carriers and partners.

### Supplier
Represents verified or potential suppliers.

### Customer
Represents buyers and demand-side organizations.

### Commodity
Represents products, materials and tradable goods.

### CommodityGrade
Represents grade or quality variation.

### Offer
Represents supplier offers.

### RFQ
Represents buyer requests.

### Contract
Represents commercial agreements.

### Shipment
Represents logistics execution.

### Carrier
Represents logistics service providers.

### Route
Represents movement path.

### Corridor
Represents strategic trade and transit corridors.

### Port
Represents maritime gateways.

### Border
Represents border crossing points.

### Warehouse
Represents storage and logistics locations.

### Document
Represents contracts, certificates, TDS, MSDS and evidence.

### Certificate
Represents certifications and approvals.

### TrustProfile
Represents trust and reputation state.

### ComplianceCase
Represents compliance checks and cases.

### MarketSignal
Represents market signals, price trends and demand/supply insights.

### KnowledgeAsset
Represents approved knowledge sources used by AI.

---

## 4. Core Relationships

- Organization OPERATES_AS Supplier
- Organization OPERATES_AS Customer
- Supplier SUPPLIES Commodity
- Commodity HAS_GRADE CommodityGrade
- Supplier PUBLISHES Offer
- Offer OFFERS Commodity
- Customer CREATES RFQ
- RFQ REQUESTS Commodity
- Supplier RESPONDS_TO RFQ
- RFQ RESULTS_IN Contract
- Contract HAS_PARTY Organization
- Contract REFERENCES Document
- Contract CREATES Shipment
- Shipment CARRIED_BY Carrier
- Shipment USES Route
- Route BELONGS_TO Corridor
- Route PASSES_THROUGH Port
- Route CROSSES Border
- Shipment STORED_AT Warehouse
- Organization HAS_TRUST_PROFILE TrustProfile
- Organization HAS_COMPLIANCE_CASE ComplianceCase
- Commodity AFFECTED_BY MarketSignal
- KnowledgeAsset DESCRIBES Commodity
- KnowledgeAsset REFERENCES Document

---

## 5. Commodity Knowledge Graph

Purpose:

To support commodity classification, product search, HS Code mapping, MSDS/TDS generation and commodity intelligence.

Key relationships:

- Commodity BELONGS_TO CommodityFamily
- Commodity HAS_GRADE CommodityGrade
- Commodity HAS_SPECIFICATION Specification
- Commodity HAS_HS_CODE HSCode
- Commodity HAS_UN_CODE UNCode
- Commodity HAS_CAS_NUMBER CASNumber
- Commodity REQUIRES_DOCUMENT MSDS
- Commodity REQUIRES_DOCUMENT TDS
- Supplier SUPPLIES Commodity

---

## 6. Supplier Knowledge Graph

Purpose:

To support supplier discovery, supplier risk analysis, supplier recommendation and RFQ matching.

Key relationships:

- Supplier HAS_CAPABILITY Commodity
- Supplier HAS_CERTIFICATE Certificate
- Supplier HAS_TRUST_PROFILE TrustProfile
- Supplier OPERATES_IN Country
- Supplier PUBLISHED Offer
- Supplier RESPONDED_TO RFQ
- Supplier SIGNED Contract

---

## 7. Trade Knowledge Graph

Purpose:

To support RFQ, offer, negotiation, award and contract intelligence.

Key relationships:

- Customer CREATED RFQ
- RFQ REQUESTS Commodity
- Supplier RESPONDED_TO RFQ
- Offer MATCHED_TO RFQ
- RFQ AWARDED_TO Supplier
- AwardDecision GENERATED Contract
- Contract CREATES Shipment

---

## 8. Contract Knowledge Graph

Purpose:

To support contract search, obligation extraction, risk analysis and AI contract assistant.

Key relationships:

- Contract HAS_PARTY Organization
- Contract CONTAINS Commodity
- Contract HAS_OBLIGATION Obligation
- Contract HAS_MILESTONE Milestone
- Contract HAS_DOCUMENT Document
- Contract HAS_AMENDMENT Amendment
- Contract HAS_RISK ContractRisk

---

## 9. Logistics Knowledge Graph

Purpose:

To support shipment tracking, route intelligence, ETA prediction, delay analysis and carrier recommendation.

Key relationships:

- Shipment CARRIED_BY Carrier
- Shipment USES Route
- Route HAS_SEGMENT RouteSegment
- RouteSegment PASSES_THROUGH Location
- Shipment HAS_TRACKING_EVENT TrackingEvent
- Shipment HAS_POD ProofOfDelivery
- Carrier OWNS Vehicle
- Driver OPERATES Vehicle

---

## 10. Corridor Knowledge Graph

Purpose:

To support strategic corridor intelligence and transit analytics.

Key relationships:

- Corridor CONNECTS Country
- Corridor INCLUDES Border
- Corridor INCLUDES Port
- Corridor INCLUDES RailTerminal
- Corridor USED_BY Shipment
- Corridor AFFECTED_BY RiskEvent
- Corridor HAS_PERFORMANCE_METRIC CorridorMetric

---

## 11. Compliance Knowledge Graph

Purpose:

To support compliance checks, regulatory intelligence and audit.

Key relationships:

- Organization HAS_COMPLIANCE_CASE ComplianceCase
- ComplianceCase REFERENCES Regulation
- Contract CHECKED_BY ComplianceCase
- Shipment CHECKED_BY ComplianceCase
- Commodity SUBJECT_TO Regulation
- Document PROVIDES_EVIDENCE_FOR ComplianceCase

---

## 12. Market Intelligence Graph

Purpose:

To support market signal analysis, price intelligence and opportunity discovery.

Key relationships:

- MarketSignal AFFECTS Commodity
- MarketSignal AFFECTS Corridor
- MarketSignal CREATES Opportunity
- Opportunity RELATED_TO Commodity
- Opportunity TARGETS Country
- PriceIndex TRACKS Commodity

---

## 13. GraphRAG Readiness

The graph must support:

- Entity retrieval
- Relationship traversal
- Context expansion
- Source citation
- Semantic enrichment
- Multi-hop reasoning

---

## 14. AI Agent Access

Agents use the graph as follows:

- Commodity Agent queries commodity graph.
- Supplier Agent queries supplier graph.
- Market Agent queries market graph.
- Logistics Agent queries logistics graph.
- Contract Agent queries contract graph.
- Compliance Agent queries compliance graph.
- Executive Copilot queries enterprise graph.

---

## 15. Future Physical Mapping

This model can be implemented using:

- Neo4j
- PostgreSQL graph-style relational mapping
- RDF / OWL
- GraphRAG layer
- Vector + Graph hybrid search

---

**End of Artifact**

AA-08_Knowledge_Graph_Model_v1.0