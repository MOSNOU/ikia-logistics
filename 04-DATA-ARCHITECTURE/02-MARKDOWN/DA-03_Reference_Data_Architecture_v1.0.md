DA-03_Reference_Data_Architecture_v1.0
معماری داده‌های مرجع پلتفرم iKIA
Document Code: DA-03
Version: 1.0
Status: Draft
Classification: Data Architecture Document
 
1. مقدمه
Reference Data مجموعه‌ای از داده‌های استاندارد، کنترل‌شده و کم‌تغییر است که در تمام دامنه‌های پلتفرم استفاده می‌شود.
در iKIA، داده‌های مرجع نقش ستون فقرات استانداردسازی داده، یکپارچگی فرایندها، تحلیل داده، هوش مصنوعی و تبادل اطلاعات با سامانه‌های خارجی را بر عهده دارند.
 
2. اهداف معماری داده‌های مرجع
•	ایجاد زبان مشترک داده‌ای
•	جلوگیری از ناسازگاری داده
•	استانداردسازی تبادل داده
•	پشتیبانی از MDM
•	پشتیبانی از AI Classification
•	پشتیبانی از Analytics
•	پشتیبانی از Integration
•	تضمین کیفیت داده
 
3. اصول طراحی
Single Reference Source
Controlled Change
Version Managed
Auditable
Globally Aligned
Locally Adapted
Reusable
Governed
4. ساختار کلان Reference Data

Geographic Reference Data

Commercial Reference Data

Commodity Reference Data

Logistics Reference Data

Governance Reference Data

Security Reference Data

AI Reference Data

5. Geographic Reference Data
 
RD-GEO-01 Countries
Standard
ISO 3166
Attributes
•	Country Code
•	Country Name
•	Alpha-2
•	Alpha-3
•	Numeric Code
•	Region
 
RD-GEO-02 Regions
Examples
•	Middle East
•	Europe
•	Central Asia
•	South Asia
•	East Asia
 
RD-GEO-03 Provinces
Examples
•	Tehran
•	Khorasan Razavi
•	Istanbul
•	Guangdong
 
RD-GEO-04 Cities
Attributes
•	City Code
•	City Name
•	Province
•	Country
 
RD-GEO-05 Ports
Examples
•	Shahid Rajaee
•	Imam Khomeini
•	Jebel Ali
•	Mersin
•	Novorossiysk
Attributes
•	Port Code
•	UNLOCODE
•	Country
•	Port Type
 
RD-GEO-06 Airports
Standard
IATA
ICAO
 
RD-GEO-07 Borders
Examples
•	Bazargan
•	Sarakhs
•	Astara
•	Mirjaveh
•	Bashmaq
 
RD-GEO-08 Rail Terminals
Attributes
•	Terminal Code
•	Country
•	Capacity
•	Rail Network
 
RD-GEO-09 Logistics Hubs
Types
•	Port Hub
•	Rail Hub
•	Road Hub
•	Air Hub
•	Multimodal Hub
 
RD-GEO-10 Free Zones
Examples
•	Kish
•	Qeshm
•	Aras
•	Maku
•	Chabahar
 
6. Iran Logistics Geography Model
برای iKIA یک مدل اختصاصی جغرافیای لجستیکی ایران تعریف می‌شود.
 
Logistics Regions
North Corridor

South Corridor

East Corridor

West Corridor

Central Corridor

Strategic Corridors
INSTC

China–Central Asia–Iran

Persian Gulf Corridor

East-West Corridor

Turkey Transit Corridor

Caspian Corridor

7. Commercial Reference Data
 
RD-COM-01 Currencies
Standard
ISO 4217
Examples
USD
EUR
AED
CNY
TRY
RUB
IRR

RD-COM-02 Exchange Rate Types
Official

Market

Customs

Central Bank

Contractual

RD-COM-03 Incoterms
Standard
Incoterms 2020
EXW
FCA
FOB
CFR
CIF
DAP
DPU
DDP

RD-COM-04 Payment Terms
Advance

LC

SBLC

CAD

Open Account

Escrow

RD-COM-05 Contract Types
Spot

Framework

Annual

Call-Off

Master Agreement

RD-COM-06 Tax Categories
VAT

Export Exempt

Import Duty

Special Economic Zone

8. Commodity Reference Data
 
RD-CMD-01 Commodity Categories
Level 1
Energy

Petrochemical

Chemical

Mining

Metals

Agriculture

Construction Materials

Industrial Equipment

RD-CMD-02 Commodity Families
مثال:
Bitumen

Methanol

Urea

LPG

Polyethylene

Copper Cathode

Iron Ore

RD-CMD-03 HS Codes
Standard
WCO Harmonized System
Structure
Chapter

Heading

Subheading

National Extension

Chapter

Heading

Subheading

National Extension

RD-CMD-04 UN Codes
کدهای سازمان ملل برای کالاهای خطرناک.
 
RD-CMD-05 CAS Numbers
برای مواد شیمیایی.
 
RD-CMD-06 Packaging Types
Bulk

Bag

Jumbo Bag

Drum

IBC

Tank

Container

Flexitank

RD-CMD-07 Units Of Measure
Standard
UNECE Recommendation 20
Examples
MT
KG
L
M3
BBL
PCS

9. Commodity Taxonomy Model
ساختار رسمی طبقه‌بندی کالا:
Category
↓
Family
↓
Group
↓
Product
↓
Grade
↓
Specification

10. Logistics Reference Data
 
RD-LOG-01 Transport Modes
Road

Rail

Sea

Air

Multimodal

RD-LOG-02 Vehicle Types
Truck

Tanker

Trailer

Container Chassis

Rail Wagon

Locomotive

RD-LOG-03 Container Types
20GP

40GP

40HC

Tank Container

Reefer

Open Top

Flat Rack

RD-LOG-04 Shipment Status Codes
Created

Planned

Assigned

Dispatched

In Transit

Delivered

Closed

RD-LOG-05 Route Types
Domestic

Export

Import

Transit

Cross Border

RD-LOG-06 Carrier Categories
Road Carrier

Rail Operator

Shipping Line

Airline

3PL

4PL

11. Transit Corridor Codes
IKIA-COR-001
IKIA-COR-002
...

Examples
IKIA-COR-INSTC

IKIA-COR-TURKEY

IKIA-COR-CASPIAN

IKIA-COR-CHINA

12. Border Crossing Codes
IKIA-BRD-BAZARGAN

IKIA-BRD-SARAKHS

IKIA-BRD-ASTARA

IKIA-BRD-BASHMAGH

13. Port Codes
IKIA-PORT-BNDR

IKIA-PORT-IKP

IKIA-PORT-JEA

14. Warehouse Types
General

Bonded

Cold Storage

Hazmat

Tank Farm

Container Yard

15. Governance Reference Data
 
RD-GOV-01 Workflow States
Draft
Submitted
Under Review
Approved
Rejected
Completed
Cancelled
RD-GOV-02 Approval States
Pending
Approved
Rejected
Escalated

RD-GOV-03 Trust Levels
Low
Medium
High
Verified
Strategic

RD-GOV-04 Risk Levels
Low
Medium
High
Critical
RD-GOV-05 Compliance Status
Compliant
Pending
Non-Compliant
Under Review

RD-GOV-06 Audit Categories
Operational
Financial
Compliance
Security
AI

16. Security Reference Data
 
RD-SEC-01 Roles
تمام نقش‌های استاندارد سیستم.
 
RD-SEC-02 Permission Categories
Read
Write
Approve
Delete
Administer

RD-SEC-03 Access Levels
Public
Internal
Restricted
Confidential
RD-SEC-04 Data Classification
Public
Internal
Confidential
Restricted

17. AI Reference Data
 
RD-AI-01 AI Model Types
LLM

Embedding

Classification

Forecasting

Recommendation

OCR

RD-AI-02 Prompt Categories
Commodity

Supplier

Contract

RFQ

Market

Compliance

RD-AI-03 Knowledge Categories
Business

Commodity

Logistics

Legal

Compliance

Market

RD-AI-04 AI Risk Levels
Low
Medium
High
Critical


RD-AI-05 AI Confidence Levels
Very Low
Low
Medium
High
Very High

18. Reference Data Ownership Model
Domain	Owner
Geography	Data Governance
Commodity	Commodity Domain
Logistics	Logistics Domain
Commercial	Commercial Domain
Security	Security Team
AI	AI Governance Team

19. Reference Data Lifecycle
Create
↓
Review
↓
Approve
↓
Publish
↓
Use
↓
Revise
↓
Retire

20. Reference Data Governance
هر Reference Data باید:
•	مالک داشته باشد.
•	Steward داشته باشد.
•	نسخه داشته باشد.
•	تاریخچه تغییرات داشته باشد.
•	فرآیند تأیید داشته باشد.
 
21. Reference Data Quality Rules
•	کدها یکتا باشند.
•	استانداردهای بین‌المللی رعایت شوند.
•	مقادیر منسوخ علامت‌گذاری شوند.
•	داده‌های اجباری کامل باشند.
 
22. Change Management Process
Change Request
↓
Review
↓
Impact Analysis
↓
Approval
↓
Publish
↓
Notify Consumers

23. KPIهای Reference Data
•	Completeness
•	Accuracy
•	Duplicate Rate
•	Change Cycle Time
•	Consumer Satisfaction
•	Standard Compliance
 
24. Roadmap
Phase 1
•	Countries
•	Currencies
•	Incoterms
•	Commodity Taxonomy
Phase 2
•	Logistics Geography
•	Ports
•	Borders
•	Corridors
Phase 3
•	AI Reference Data
•	Knowledge Taxonomy
•	Advanced Governance
 
25. نتیجه‌گیری
Reference Data Architecture پایه استانداردسازی کل اکوسیستم iKIA است.
تمام Master Data، Workflowها، AI Models، Analytics، APIها و فرآیندهای تجاری باید از این داده‌های مرجع استفاده کنند.
 
پایان سند
DA-03_Reference_Data_Architecture_v1.0




