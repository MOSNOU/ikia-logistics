AP-03_Domain_Driven_Design_Model_v1.0
مدل طراحی دامنه‌محور پلتفرم iKIA
Document Code: AP-03
Version: 1.0
Status: Draft
Classification: Application Architecture Document
 
1. مقدمه
طراحی دامنه‌محور یا Domain Driven Design یکی از مهم‌ترین روش‌های معماری نرم‌افزارهای پیچیده است.
پلتفرم iKIA یک سیستم ساده نیست.
این پلتفرم شامل چندین دامنه پیچیده از جمله CRM، فرصت‌های تجاری، تأمین‌کنندگان، کالاها، RFQ، قرارداد، اعتماد، لجستیک، حمل، تسویه، اسناد، هوش مصنوعی و تحلیل داده است.
 
هدف این سند تعریف مرزهای دامنه‌ای، Bounded Contextها، Aggregateها، Domain Eventها و مالکیت داده در معماری نرم‌افزار iKIA است.
 
2. اصول طراحی DDD در iKIA
تمام دامنه‌ها باید بر اساس اصول زیر طراحی شوند:
•	هر دامنه مالک داده‌های خود است.
•	هیچ سرویس دیگری نباید مستقیماً دیتابیس دامنه دیگر را تغییر دهد.
•	ارتباط میان دامنه‌ها باید از طریق API و Event انجام شود.
•	هر Bounded Context باید زبان مشترک خود را داشته باشد.
•	Aggregateها باید مرز تراکنش را مشخص کنند.
•	Domain Eventها باید تغییرات مهم کسب‌وکار را منتشر کنند.
 
3. Context Map کلان
Customer Context
↓
CRM Context
↓
Opportunity Context
↓
RFQ Context
↓
Contract Context
↓
Logistics Context
↓
Shipment Context
↓
Settlement Context
↓
Analytics & AI Context

4. Bounded Context 01
Customer Context
Purpose
مدیریت موجودیت‌های مشتری، سازمان، حساب، شعبه و وضعیت عضویت.
Core Aggregates
•	Customer
•	Organization
•	Branch
•	Contact
Entities
•	Customer Profile
•	Organization Profile
•	Contact Person
•	Customer Status
Value Objects
•	Customer Type
•	Registration Number
•	Contact Info
•	Address
Domain Services
•	Customer Registration Service
•	Customer Classification Service
•	Customer Status Service
Domain Events
•	CustomerCreated
•	CustomerUpdated
•	CustomerActivated
•	CustomerSuspended
Owned Data
•	Customer
•	Organization
•	Branch
•	Contact
 
5. Bounded Context 02
CRM Context
Purpose
مدیریت روابط تجاری، سرنخ‌ها، تعاملات، حساب‌ها و چرخه فروش.
Core Aggregates
•	Lead
•	Account
•	Activity
•	Pipeline
Entities
•	Lead Source
•	Sales Activity
•	Follow-up
•	CRM Note
Value Objects
•	Lead Score
•	Activity Type
•	Pipeline Stage
Domain Services
•	Lead Qualification Service
•	Account Assignment Service
•	Sales Pipeline Service
Domain Events
•	LeadCreated
•	LeadQualified
•	AccountCreated
•	ActivityLogged
•	LeadConverted
Owned Data
•	Leads
•	CRM Activities
•	Sales Pipeline
 
6. Bounded Context 03
Opportunity Context
Purpose
مدیریت فرصت‌های تجاری، لجستیکی، تأمین، فروش و معرفی.
Core Aggregates
•	Opportunity
•	Opportunity Source
•	Opportunity Assignment
Entities
•	Opportunity Note
•	Opportunity Stage
•	Opportunity Owner
Value Objects
•	Opportunity Score
•	Opportunity Type
•	Expected Value
•	Probability
Domain Services
•	Opportunity Qualification Service
•	Opportunity Scoring Service
•	Opportunity Assignment Service
Domain Events
•	OpportunityCreated
•	OpportunityQualified
•	OpportunityAssigned
•	OpportunityClosed
•	OpportunityConverted
Owned Data
•	Opportunities
•	Opportunity Scores
•	Opportunity Lifecycle
 
7. Bounded Context 04
Supplier Context
Purpose
مدیریت تأمین‌کنندگان، توانمندی‌ها، مدارک، وضعیت اعتبار و عملکرد.
Core Aggregates
•	Supplier
•	Supplier Capability
•	Supplier Profile
Entities
•	Supplier Document
•	Supplier Contact
•	Supplier Product
•	Supplier Performance
Value Objects
•	Supplier Type
•	Capability Category
•	Supplier Rating
Domain Services
•	Supplier Registration Service
•	Supplier Qualification Service
•	Supplier Performance Service
Domain Events
•	SupplierRegistered
•	SupplierProfileCompleted
•	SupplierVerified
•	SupplierApproved
•	SupplierSuspended
Owned Data
•	Supplier
•	Supplier Capability
•	Supplier Documents
•	Supplier Performance
 
8. Bounded Context 05
Commodity Context
Purpose
مدیریت کالاها، دسته‌بندی، کدینگ، مشخصات فنی و اسناد فنی.
Core Aggregates
•	Commodity
•	Commodity Category
•	Product Code
•	Technical Specification
Entities
•	Commodity Attribute
•	Product Document
•	Product Grade
•	Commodity Family
Value Objects
•	HS Code
•	Product Code
•	Specification Value
•	Unit of Measure
Domain Services
•	Commodity Classification Service
•	Product Coding Service
•	Specification Validation Service
Domain Events
•	CommodityCreated
•	CommodityClassified
•	ProductCodeAssigned
•	SpecificationUpdated
•	CommodityApproved
Owned Data
•	Commodity Master
•	Product Code
•	Technical Specifications
 
9. Bounded Context 06
Offer Context
Purpose
مدیریت عرضه‌ها، تابلو عرضه، وضعیت انتشار و اعتبار زمانی عرضه.
Core Aggregates
•	Offer
•	Offer Board
•	Offer Terms
Entities
•	Offer Item
•	Offer Attachment
•	Offer Validity
•	Buyer Interest
Value Objects
•	Price
•	Quantity
•	Delivery Terms
•	Validity Period
Domain Services
•	Offer Validation Service
•	Offer Publishing Service
•	Offer Matching Service
Domain Events
•	OfferCreated
•	OfferValidated
•	OfferPublished
•	OfferExpired
•	BuyerInterestRegistered
Owned Data
•	Offers
•	Offer Terms
•	Offer Status
 
10. Bounded Context 07
RFQ Context
Purpose
مدیریت درخواست قیمت، انتشار RFQ، دریافت پاسخ و انتخاب پیشنهاد.
Core Aggregates
•	RFQ
•	RFQ Item
•	RFQ Response
•	RFQ Award
Entities
•	Supplier Invitation
•	Evaluation Criteria
•	Technical Response
•	Commercial Response
Value Objects
•	Required Quantity
•	Target Price
•	Delivery Window
•	Payment Terms
Domain Services
•	RFQ Matching Service
•	RFQ Evaluation Service
•	RFQ Award Service
Domain Events
•	RFQCreated
•	RFQPublished
•	SupplierInvited
•	RFQResponseReceived
•	RFQAwarded
Owned Data
•	RFQ
•	RFQ Items
•	RFQ Responses
•	RFQ Awards
 
11. Bounded Context 08
Contract Context
Purpose
مدیریت قراردادها، نسخه‌ها، طرفین، تعهدات، پذیرش دیجیتال و امضا.
Core Aggregates
•	Contract
•	Contract Version
•	Obligation
•	Signature
Entities
•	Contract Party
•	Contract Clause
•	Contract Attachment
•	Acceptance Record
Value Objects
•	Contract Status
•	Effective Date
•	Expiry Date
•	Contract Value
Domain Services
•	Contract Authoring Service
•	Digital Signature Service
•	Obligation Tracking Service
Domain Events
•	ContractDrafted
•	ContractReviewed
•	ContractAccepted
•	ContractSigned
•	ObligationCreated
Owned Data
•	Contracts
•	Versions
•	Obligations
•	Signature Records
 
12. Bounded Context 09
Trust Context
Purpose
مدیریت اعتماد، احراز هویت، امتیاز اعتماد، شهرت و Trust Graph.
Core Aggregates
•	Trust Profile
•	Verification Case
•	Trust Score
•	Reputation Record
Entities
•	KYC Record
•	KYB Record
•	Risk Flag
•	Trust Evidence
Value Objects
•	Trust Level
•	Risk Level
•	Score Value
•	Verification Status
Domain Services
•	KYC Service
•	KYB Service
•	Trust Scoring Service
•	Reputation Service
Domain Events
•	IdentityVerified
•	BusinessVerified
•	TrustScoreUpdated
•	TrustStatusChanged
•	RiskFlagRaised
Owned Data
•	Trust Profiles
•	Verification Records
•	Trust Scores
•	Reputation Records
 
13. Bounded Context 10
Compliance Context
Purpose
مدیریت انطباق قانونی، مقرراتی، تجاری، تحریمی و حسابرسی.
Core Aggregates
•	Compliance Case
•	Compliance Rule
•	Screening Result
Entities
•	Regulatory Requirement
•	Audit Finding
•	Compliance Evidence
Value Objects
•	Compliance Status
•	Risk Category
•	Rule Severity
Domain Services
•	Sanctions Screening Service
•	Regulatory Check Service
•	Compliance Case Service
Domain Events
•	ComplianceCheckRequested
•	CompliancePassed
•	ComplianceFailed
•	ComplianceCaseOpened
Owned Data
•	Compliance Rules
•	Screening Results
•	Compliance Cases
 
14. Bounded Context 11
Logistics Context
Purpose
مدیریت برنامه‌ریزی حمل، مسیر، ظرفیت، نوع حمل و حمل چندوجهی.
Core Aggregates
•	Logistics Order
•	Transport Plan
•	Route Plan
•	Capacity Plan
Entities
•	Transport Mode
•	Route Segment
•	Loading Point
•	Delivery Point
Value Objects
•	Route
•	Distance
•	ETA
•	Capacity
Domain Services
•	Route Optimization Service
•	Transport Planning Service
•	Capacity Matching Service
Domain Events
•	LogisticsOrderCreated
•	TransportPlanCreated
•	RouteOptimized
•	CarrierRequested
Owned Data
•	Logistics Orders
•	Transport Plans
•	Route Plans
 
15. Bounded Context 12
Carrier Context
Purpose
مدیریت شرکت‌های حمل، ناوگان، رانندگان، مجوزها و عملکرد.
Core Aggregates
•	Carrier
•	Fleet
•	Vehicle
•	Driver
Entities
•	Carrier License
•	Vehicle Document
•	Driver Document
•	Carrier Performance
Value Objects
•	Vehicle Type
•	Plate Number
•	License Status
•	Driver Status
Domain Services
•	Carrier Qualification Service
•	Fleet Registration Service
•	Driver Verification Service
Domain Events
•	CarrierRegistered
•	VehicleAdded
•	DriverVerified
•	CarrierApproved
Owned Data
•	Carriers
•	Vehicles
•	Drivers
•	Fleet Records
 
16. Bounded Context 13
Shipment Context
Purpose
مدیریت چرخه عمر محموله از ایجاد تا تحویل و POD.
Core Aggregates
•	Shipment
•	Shipment Leg
•	Tracking Event
•	Proof of Delivery
Entities
•	Shipment Item
•	Shipment Status
•	Delivery Evidence
•	Exception Event
Value Objects
•	Tracking Location
•	Shipment Status
•	Delivery Timestamp
Domain Services
•	Shipment Execution Service
•	Tracking Service
•	POD Service
•	Exception Handling Service
Domain Events
•	ShipmentCreated
•	ShipmentStarted
•	ShipmentDelayed
•	ShipmentDelivered
•	PODUploaded
Owned Data
•	Shipments
•	Tracking Events
•	POD Records
 
17. Bounded Context 14
Settlement Context
Purpose
مدیریت صورتحساب، پرداخت، تسویه و ثبت درآمد.
Core Aggregates
•	Invoice
•	Settlement
•	Payment Record
•	Revenue Record
Entities
•	Invoice Item
•	Settlement Approval
•	Payment Confirmation
Value Objects
•	Amount
•	Currency
•	Payment Status
•	Settlement Status
Domain Services
•	Invoice Service
•	Settlement Approval Service
•	Revenue Recognition Service
Domain Events
•	InvoiceIssued
•	SettlementApproved
•	PaymentConfirmed
•	RevenueRecognized
Owned Data
•	Invoices
•	Payments
•	Settlements
•	Revenue Records
 
18. Bounded Context 15
Escrow Context
Purpose
مدیریت نگهداری امن وجوه، شرایط آزادسازی و حسابرسی Escrow.
Core Aggregates
•	Escrow Case
•	Escrow Rule
•	Fund Hold
•	Release Record
Domain Events
•	EscrowCreated
•	FundHeld
•	ReleaseApproved
•	FundReleased
•	EscrowClosed
Owned Data
•	Escrow Cases
•	Fund Status
•	Release Records
 
19. Bounded Context 16
Claims Context
Purpose
مدیریت رخدادها، خسارات، اختلافات و حل پرونده.
Core Aggregates
•	Claim
•	Incident
•	Evidence
•	Resolution
Domain Events
•	ClaimCreated
•	EvidenceSubmitted
•	ResolutionProposed
•	ClaimClosed
Owned Data
•	Claims
•	Incidents
•	Evidence
•	Resolutions
 
20. Bounded Context 17
Document Context
Purpose
مدیریت اسناد، فایل‌ها، نسخه‌ها، مدارک و شواهد دیجیتال.
Core Aggregates
•	Document
•	Document Version
•	File Object
•	Evidence Record
Domain Events
•	DocumentUploaded
•	DocumentVersionCreated
•	DocumentApproved
•	EvidenceRegistered
 
21. Bounded Context 18
Workflow Context
Purpose
مدیریت فرآیندها، وضعیت‌ها، SLA، Escalation و اتوماسیون.
Core Aggregates
•	Workflow Definition
•	Workflow Instance
•	Task
•	SLA Rule
Domain Events
•	WorkflowStarted
•	TaskAssigned
•	TaskCompleted
•	SLAExceeded
•	WorkflowCompleted
 
22. Bounded Context 19
AI Context
Purpose
مدیریت مدل‌های AI، پیشنهادها، پیش‌بینی‌ها، تحلیل اسناد و Copilot.
Core Aggregates
•	AI Model
•	Prediction
•	Recommendation
•	Prompt Template
Domain Events
•	PredictionGenerated
•	RecommendationCreated
•	AIDocumentGenerated
•	ModelUpdated
 
23. Bounded Context 20
Analytics Context
Purpose
مدیریت گزارش‌ها، KPIها، داشبوردها و تحلیل‌های مدیریتی.
Core Aggregates
•	Report
•	Dashboard
•	KPI
•	Insight
Domain Events
•	KPIUpdated
•	ReportGenerated
•	InsightCreated
 
24. Context Relationship Model
Customer → CRM → Opportunity → RFQ → Contract

Supplier → Offer → RFQ → Contract

Contract → Logistics → Shipment → Settlement

Trust → All Domains

Compliance → All Regulated Domains

Document → All Domains

Workflow → All Domains

AI → All Domains

Analytics ← All Domains
25. Event Catalog کلیدی
CustomerCreated
LeadQualified
OpportunityCreated
SupplierApproved
CommodityPublished
OfferPublished
RFQCreated
RFQResponseReceived
ContractSigned
TrustScoreUpdated
TransportPlanCreated
ShipmentDelivered
PODUploaded
InvoiceIssued
PaymentConfirmed
ClaimClosed

26. Ownership Matrix

Domain	Owns Data	Publishes Events	Consumes Events
Customer	Customer, Organization	CustomerCreated	IdentityVerified
CRM	Lead, Account	LeadQualified	CustomerCreated
Supplier	Supplier	SupplierApproved	TrustScoreUpdated
Commodity	Commodity	CommodityPublished	SupplierApproved
RFQ	RFQ	RFQCreated	OfferPublished
Contract	Contract	ContractSigned	RFQAwarded
Logistics	Transport Plan	TransportPlanCreated	ContractSigned
Shipment	Shipment	ShipmentDelivered	TransportPlanCreated
Settlement	Invoice, Payment	PaymentConfirmed	ShipmentDelivered
Trust	Trust Score	TrustScoreUpdated	Verification Events


27. Service Boundary Rules
•	هر Context مالک دیتابیس خود است.
•	تغییر داده فقط از طریق API همان Context مجاز است.
•	Eventها برای اطلاع‌رسانی بین Contextها استفاده می‌شوند.
•	Shared Database ممنوع است.
•	Direct Write به دیتابیس دیگر ممنوع است.
•	Integration از طریق API Gateway و Event Bus انجام می‌شود.
 
28. MVP Contexts
برای MVP اولیه:

Customer
CRM
Opportunity
Supplier
Commodity
Offer
RFQ
Trust
Document
Workflow
Identity
Notification

29. نتیجه‌گیری
این DDD Model مرجع اصلی طراحی Microserviceها، دیتابیس‌ها، APIها، Eventها و ساختار کد iKIA است.
هر توسعه فنی باید با این سند همسو باشد.
 
پایان سند
AP-03_Domain_Driven_Design_Model_v1.0
 






