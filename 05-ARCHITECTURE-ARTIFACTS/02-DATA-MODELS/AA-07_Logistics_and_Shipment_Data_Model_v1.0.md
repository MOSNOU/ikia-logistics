# AA-07_Logistics_and_Shipment_Data_Model_v1.0

# iKIA Logistics and Shipment Data Model

## 1. Scope

This artifact defines the Logistics and Shipment Data Model for the iKIA platform.

It supports logistics orders, shipment execution, multimodal transport, carrier assignment, route planning, corridor monitoring, shipment tracking, proof of delivery, ETA prediction, logistics cost, risk, compliance and logistics knowledge graph.

---

## 2. Model Objectives

- Support end-to-end shipment lifecycle.
- Support road, rail, sea, air and multimodal transport.
- Support carrier, vehicle and driver assignment.
- Support route and corridor intelligence.
- Support tracking events and visibility.
- Support proof of delivery.
- Support ETA prediction and delay management.
- Support logistics cost and freight rate management.
- Support logistics analytics and knowledge graph.

---

## 3. Core Logistics Entities

### LogisticsOrder

Main operational order created from contract, RFQ, offer or direct shipment request.

Key attributes:

- LogisticsOrderID
- ContractID
- CustomerID
- OriginLocationID
- DestinationLocationID
- TransportMode
- Status
- RequiredPickupDate
- RequiredDeliveryDate

---

### Shipment

Executable shipment record.

Key attributes:

- ShipmentID
- LogisticsOrderID
- CarrierID
- Status
- ShipmentType
- PlannedStartDate
- ActualStartDate
- PlannedDeliveryDate
- ActualDeliveryDate

---

### ShipmentItem

Goods included in shipment.

---

### ShipmentLeg

Segment of shipment route.

Examples:

- Road Leg
- Rail Leg
- Sea Leg
- Air Leg
- Border Crossing Leg

---

### ShipmentMilestone

Operational milestone.

Examples:

- Pickup Scheduled
- Loaded
- Departed
- Arrived Border
- Customs Cleared
- Delivered
- POD Uploaded

---

### ShipmentTrackingEvent

Real-time or manual tracking event.

---

### ProofOfDelivery

Delivery confirmation and evidence.

---

## 4. Carrier and Fleet Entities

### Carrier

Transport service provider.

---

### CarrierCapability

Carrier service capabilities.

---

### CarrierContract

Contractual relationship with carrier.

---

### Vehicle

Vehicle or transport asset.

---

### VehicleType

Reference vehicle type.

---

### Driver

Driver or operator.

---

### TrackingDevice

GPS or IoT tracking device.

---

## 5. Route and Corridor Entities

### Route

Planned route.

---

### RouteSegment

Segment of route.

---

### Corridor

Strategic trade or logistics corridor.

Examples:

- INSTC
- Turkey Corridor
- Caspian Corridor
- Persian Gulf Corridor

---

### Port

Sea port.

---

### BorderCrossing

Border crossing point.

---

### Terminal

Rail, road or multimodal terminal.

---

### Warehouse

Storage or transshipment location.

---

## 6. Visibility and Prediction Entities

### ETARecord

Estimated Time of Arrival prediction record.

---

### DelayEvent

Delay reason and impact.

---

### ShipmentException

Operational exception.

---

## 7. Documents and Compliance

### LogisticsDocument

Documents related to logistics execution.

---

### CustomsDocument

Customs and transit documents.

---

### InspectionRecord

Inspection and survey records.

---

### LogisticsCompliance

Compliance checks related to shipment.

---

## 8. Cost and Rate Entities

### FreightRate

Rate offered or contracted for logistics services.

---

### LogisticsCost

Actual or estimated logistics costs.

---

### LogisticsRisk

Operational, corridor, carrier or geopolitical logistics risk.

---

## 9. Key Relationships

- Contract may create LogisticsOrder.
- LogisticsOrder creates one or more Shipments.
- Shipment contains ShipmentItems.
- Shipment consists of ShipmentLegs.
- Shipment has Milestones.
- Shipment has TrackingEvents.
- Shipment produces ProofOfDelivery.
- Shipment is assigned to Carrier.
- Carrier has Vehicles and Drivers.
- Vehicle may have TrackingDevice.
- Shipment uses Route.
- Route contains RouteSegments.
- Route may belong to Corridor.
- RouteSegment may pass through Port, BorderCrossing, Terminal or Warehouse.
- Shipment may have ETARecords.
- Shipment may have DelayEvents and Exceptions.
- Shipment may have LogisticsDocuments and CustomsDocuments.
- Shipment may have InspectionRecords.
- Shipment may have Compliance records.
- Shipment may have FreightRates and LogisticsCosts.
- LogisticsRisk may be linked to Corridor, Route, Carrier or Shipment.

---

## 10. Shipment Lifecycle

```text
Created
↓
Planned
↓
Carrier Assigned
↓
Dispatched
↓
In Transit
↓
At Border / Port / Terminal
↓
Customs / Inspection
↓
Delivered
↓
POD Uploaded
↓
Closed

11. Multimodal Logistics Model
The model supports multimodal shipment through ShipmentLeg.
Each leg may have:
•	Mode
•	Carrier
•	Vehicle / Vessel / Wagon
•	Origin
•	Destination
•	Planned Time
•	Actual Time
•	Status
 
12. Corridor Intelligence Readiness
Corridor analytics are enabled by linking:
Shipment
↓
Route
↓
RouteSegment
↓
Corridor
↓
Border / Port / Terminal
↓
Delay / Risk / Cost / ETA

13. AI Readiness
This model supports:
•	ETA prediction
•	Delay prediction
•	Carrier recommendation
•	Route recommendation
•	Corridor risk scoring
•	Shipment exception detection
•	Logistics cost forecasting
•	Control Tower alerts
 
14. Analytics Readiness
This model supports:
•	Shipment On-Time Delivery Rate
•	Average Transit Time
•	Delay Rate
•	Carrier Performance Score
•	Corridor Performance Index
•	Freight Cost per Ton
•	POD Completion Rate
•	Exception Resolution Time
 
15. Data Governance
Each logistics record must have:
•	Logistics Data Owner
•	Logistics Data Steward
•	Shipment Status Owner
•	Tracking Event Source
•	Proof of Delivery Evidence
•	Audit Trail
•	Data Classification
 
16. Future Physical Mapping
This model will be mapped to:
•	PostgreSQL tables
•	Supabase tables
•	Shipment APIs
•	Carrier APIs
•	Tracking APIs
•	Control Tower
•	ETA Engine
•	Route Optimization
•	Logistics Analytics Mart
•	Logistics Knowledge Graph
 
End of Artifact

