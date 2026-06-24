AP-02_Platform_Service_Catalog_v1.0
کاتالوگ سرویس‌های پلتفرم iKIA
Document Code: AP-02
Version: 1.0
Status: Draft
Classification: Application Architecture Document
 
1. مقدمه
کاتالوگ سرویس‌ها مرجع رسمی تمام سرویس‌های نرم‌افزاری، دامنه‌ای، مشترک، هوشمند و یکپارچه‌سازی پلتفرم iKIA است.
این سند مشخص می‌کند که هر سرویس چه مسئولیتی دارد، مالک چه داده‌هایی است، چه APIهایی ارائه می‌دهد، چه رویدادهایی تولید می‌کند و به چه سرویس‌هایی وابسته است.
 
2. اصول طراحی Service Catalog
تمام سرویس‌های iKIA باید بر اساس اصول زیر طراحی شوند:
•	Domain Driven
•	API First
•	Event Driven
•	Secure by Design
•	Observable
•	Independently Deployable
•	Data Ownership Clear
•	Multi-Tenant Ready
 
3. دسته‌بندی سرویس‌ها
سرویس‌های پلتفرم در پنج گروه اصلی طبقه‌بندی می‌شوند:

Domain Services
Intelligence Services
Shared Services
Integration Services
Platform Services

4. Domain Services
Domain Services هسته اصلی منطق کسب‌وکار iKIA هستند.
 
DS-01 Customer Service
Purpose
مدیریت مشتریان حقیقی و حقوقی پلتفرم.
Owner Domain
Customer & CRM
Key Functions
•	Customer Profile
•	Customer Lifecycle
•	Customer Status
•	Customer Segmentation
Data Owned
•	Customer
•	Customer Profile
•	Customer Status
•	Customer Segment
APIs Exposed
•	Create Customer
•	Update Customer
•	Get Customer
•	Search Customers
Events Published
•	CustomerCreated
•	CustomerUpdated
•	CustomerActivated
•	CustomerSuspended
Consumers
•	CRM Service
•	Trust Service
•	Billing Service
•	Analytics Service
 
DS-02 CRM Service
Purpose
مدیریت روابط تجاری، سرنخ‌ها، حساب‌ها و فرصت‌ها.
Key Functions
•	Lead Management
•	Account Management
•	Activity Tracking
•	Sales Pipeline
Data Owned
•	Lead
•	Account
•	Activity
•	Pipeline
Events Published
•	LeadCreated
•	LeadQualified
•	AccountCreated
•	ActivityLogged
APIs Exposed
•	Create Lead
•	Qualify Lead
•	Create Account
•	Log Activity
 
DS-03 Opportunity Service
Purpose
مدیریت فرصت‌های تجاری، لجستیکی و زنجیره تأمین.
Key Functions
•	Opportunity Registration
•	Qualification
•	Prioritization
•	Lifecycle Management
Data Owned
•	Opportunity
•	Opportunity Source
•	Opportunity Status
•	Opportunity Score
Events Published
•	OpportunityCreated
•	OpportunityQualified
•	OpportunityAssigned
•	OpportunityClosed
 
DS-04 Supplier Service
Purpose
مدیریت تامین‌کنندگان، پروفایل‌ها، مدارک و وضعیت اعتماد.
Key Functions
•	Supplier Registration
•	Supplier Profile
•	Supplier Qualification
•	Supplier Performance
Data Owned
•	Supplier
•	Supplier Capability
•	Supplier Document
•	Supplier Status
Events Published
•	SupplierRegistered
•	SupplierVerified
•	SupplierApproved
•	SupplierSuspended
 
DS-05 Commodity Service
Purpose
مدیریت کالاها، دسته‌بندی، کدینگ و مشخصات فنی.
Key Functions
•	Commodity Registry
•	Category Management
•	Product Coding
•	Specification Management
Data Owned
•	Commodity
•	Category
•	Product Code
•	Specification
Events Published
•	CommodityCreated
•	CommodityClassified
•	CommodityApproved
•	CommodityPublished
 
DS-06 Offer Service
Purpose
مدیریت تابلو عرضه و تقاضا.
Key Functions
•	Offer Intake
•	Offer Validation
•	Offer Publication
•	Offer Matching
Data Owned
•	Offer
•	Offer Status
•	Offer Validity
•	Offer Terms
Events Published
•	OfferCreated
•	OfferValidated
•	OfferPublished
•	OfferExpired
 
DS-07 RFQ Service
Purpose
مدیریت درخواست‌های قیمت و فرآیند دریافت پیشنهاد.
Key Functions
•	RFQ Creation
•	RFQ Distribution
•	Supplier Matching
•	Offer Evaluation
Data Owned
•	RFQ
•	RFQ Item
•	RFQ Response
•	Evaluation
Events Published
•	RFQCreated
•	RFQPublished
•	RFQResponseReceived
•	RFQAwarded
 
DS-08 Contract Service
Purpose
مدیریت قراردادها، نسخه‌ها، امضا و تعهدات.
Key Functions
•	Contract Authoring
•	Negotiation
•	Digital Acceptance
•	Obligation Tracking
Data Owned
•	Contract
•	Contract Version
•	Contract Party
•	Obligation
Events Published
•	ContractDrafted
•	ContractAccepted
•	ContractSigned
•	ObligationCreated
 
DS-09 Trust Service
Purpose
مدیریت اعتماد، اعتبارسنجی، امتیازدهی و Trust Graph.
Key Functions
•	KYC
•	KYB
•	Trust Score
•	Reputation Score
•	Trust Graph
Data Owned
•	Trust Profile
•	Verification Record
•	Trust Score
•	Reputation Record
Events Published
•	IdentityVerified
•	BusinessVerified
•	TrustScoreUpdated
•	TrustStatusChanged
 
DS-10 Compliance Service
Purpose
مدیریت انطباق قانونی، مقرراتی، تجاری و عملیاتی.
Key Functions
•	Compliance Rules
•	Regulatory Checks
•	Sanctions Screening
•	Audit Controls
Data Owned
•	Compliance Rule
•	Compliance Case
•	Screening Result
•	Audit Finding
Events Published
•	ComplianceCheckRequested
•	CompliancePassed
•	ComplianceFailed
•	ComplianceCaseOpened
 
DS-11 Logistics Service
Purpose
مدیریت برنامه‌ریزی حمل، مسیر، ظرفیت و عملیات لجستیکی.
Key Functions
•	Transport Planning
•	Route Planning
•	Multi-Modal Planning
•	Capacity Planning
Data Owned
•	Transport Plan
•	Route Plan
•	Capacity Plan
•	Logistics Order
Events Published
•	TransportPlanCreated
•	CarrierRequested
•	RouteOptimized
 
DS-12 Carrier Service
Purpose
مدیریت شرکت‌های حمل، رانندگان، ناوگان و عملکرد.
Key Functions
•	Carrier Registry
•	Fleet Registry
•	Driver Registry
•	Carrier Performance
Data Owned
•	Carrier
•	Vehicle
•	Driver
•	Fleet
Events Published
•	CarrierRegistered
•	VehicleAdded
•	DriverVerified
•	CarrierApproved
 
DS-13 Shipment Service
Purpose
مدیریت چرخه عمر محموله از ایجاد تا تحویل.
Key Functions
•	Shipment Creation
•	Shipment Execution
•	Tracking
•	POD
Data Owned
•	Shipment
•	Shipment Status
•	Tracking Event
•	Proof of Delivery
Events Published
•	ShipmentCreated
•	ShipmentStarted
•	ShipmentDelivered
•	PODUploaded
 
DS-14 Settlement Service
Purpose
مدیریت صورتحساب، تأیید پرداخت، تسویه و درآمد.
Key Functions
•	Invoice Management
•	Payment Approval
•	Settlement
•	Revenue Recognition
Data Owned
•	Invoice
•	Settlement
•	Payment Status
•	Revenue Record
Events Published
•	InvoiceIssued
•	SettlementApproved
•	PaymentConfirmed
•	RevenueRecognized
 
DS-15 Escrow Service
Purpose
مدیریت نگهداری و آزادسازی امن وجوه در معاملات منتخب.
Key Functions
•	Escrow Account
•	Fund Hold
•	Release Rules
•	Escrow Audit
Data Owned
•	Escrow Case
•	Escrow Rule
•	Fund Status
•	Release Record
Events Published
•	EscrowCreated
•	FundHeld
•	FundReleased
•	EscrowClosed
 
DS-16 Claims Service
Purpose
مدیریت رخدادها، خسارات، دعاوی و اختلافات.
Key Functions
•	Incident Registration
•	Evidence Collection
•	Case Management
•	Resolution
Data Owned
•	Claim
•	Incident
•	Evidence
•	Resolution
Events Published
•	ClaimCreated
•	EvidenceSubmitted
•	ResolutionProposed
•	ClaimClosed
 
5. Intelligence Services
 
IS-01 Market Intelligence Service
Purpose
تحلیل بازارها، قیمت‌ها، سیگنال‌ها و فرصت‌ها.
Key Functions
•	Market Signal Detection
•	Price Intelligence
•	Commodity Intelligence
•	Market Reports
 
IS-02 Supply Chain Intelligence Service
Purpose
تحلیل عرضه، تقاضا، ریسک و ظرفیت زنجیره تأمین.
Key Functions
•	Demand Forecasting
•	Supply Risk
•	Supplier Intelligence
•	Capacity Analysis
 
IS-03 Corridor Intelligence Service
Purpose
تحلیل کریدورها، مرزها، مسیرها و گلوگاه‌های ترانزیتی.
Key Functions
•	Corridor Monitoring
•	Border Analytics
•	Transit Time Analysis
•	Congestion Detection
 
IS-04 Analytics Service
Purpose
ارائه داشبوردها، گزارش‌ها و شاخص‌های عملکرد.
Key Functions
•	KPI Dashboards
•	BI Reports
•	Executive Analytics
•	Operational Analytics
 
IS-05 AI Copilot Service
Purpose
ارائه دستیار هوشمند برای کاربران، مدیران و اپراتورها.
Key Functions
•	Natural Language Query
•	Recommendation
•	Document Drafting
•	Risk Alerts
 
IS-06 Forecasting Service
Purpose
پیش‌بینی تقاضا، قیمت، زمان تحویل، ریسک و ظرفیت.
Key Functions
•	Demand Forecast
•	ETA Forecast
•	Price Forecast
•	Risk Forecast
 
6. Shared Services
 
SS-01 Identity Service
Purpose
احراز هویت و مدیریت دسترسی.
Key Functions
•	Authentication
•	Authorization
•	MFA
•	RBAC
 
SS-02 Notification Service
Purpose
ارسال پیام و اعلان از طریق ایمیل، پیامک، اپلیکیشن و وب.
Key Functions
•	Email
•	SMS
•	Push
•	In-App Notification
 
SS-03 Document Service
Purpose
مدیریت فایل‌ها، مدارک، نسخه‌ها و شواهد دیجیتال.
Key Functions
•	Document Repository
•	Version Control
•	File Storage
•	Digital Evidence
 
SS-04 Workflow Service
Purpose
اجرای فرآیندهای کسب‌وکار.
Key Functions
•	Workflow Definition
•	Workflow Execution
•	SLA
•	Escalation
 
SS-05 Audit Service
Purpose
ثبت رویدادها و حسابرسی فعالیت‌ها.
Key Functions
•	Audit Trail
•	Event Log
•	Activity History
•	Evidence Log
 
SS-06 Search Service
Purpose
جستجوی سراسری در داده‌ها، اسناد، کاربران، کالاها و فرصت‌ها.
Key Functions
•	Full Text Search
•	Faceted Search
•	Entity Search
•	Semantic Search
 
SS-07 File Service
Purpose
ذخیره و مدیریت فایل‌ها.
Key Functions
•	Upload
•	Download
•	Metadata
•	Access Control
 
SS-08 Configuration Service
Purpose
مدیریت تنظیمات پلتفرم، Tenant و سازمان‌ها.
 
7. Integration Services
 
IN-01 API Gateway
Purpose
درگاه واحد APIها برای سرویس‌های داخلی و خارجی.
 
IN-02 Event Bus
Purpose
انتقال رویدادهای دامنه‌ای میان سرویس‌ها.
 
IN-03 Customs Connector
Purpose
اتصال به سامانه‌های گمرکی.
 
IN-04 Bank Connector
Purpose
اتصال به بانک‌ها و سرویس‌های مالی.
 
IN-05 PSP Connector
Purpose
اتصال به پرداخت‌یارها و PSPها.
 
IN-06 ERP Connector
Purpose
اتصال به ERPهای مشتریان سازمانی.
 
IN-07 Email Connector
Purpose
خواندن و ارسال ایمیل‌های عملیاتی و تجاری.
 
IN-08 SMS Connector
Purpose
ارسال پیامک و OTP.
 
8. Platform Services
 
PS-01 Tenant Service
مدیریت مستأجرها در معماری چندمستاجری.
 
PS-02 Organization Service
مدیریت سازمان‌ها، شرکت‌ها و نهادها.
 
PS-03 Branch Service
مدیریت شعب و واحدهای سازمانی.
 
PS-04 User Service
مدیریت کاربران.
 
PS-05 Role Service
مدیریت نقش‌ها.
 
PS-06 Permission Service
مدیریت مجوزها.
 
PS-07 Monitoring Service
پایش سلامت سیستم.
 
PS-08 Observability Service
پایش لاگ، متریک و Trace.
 
9. Event Architecture
رویدادها باید برای اتصال سرویس‌ها استفاده شوند.
نمونه‌ها:

CustomerCreated
SupplierApproved
RFQCreated
OfferPublished
ContractSigned
ShipmentDelivered
PaymentConfirmed
TrustScoreUpdated

10. API Architecture
هر سرویس باید APIهای مشخص و مستند داشته باشد.
 
11. Data Ownership
هر داده باید مالک مشخص داشته باشد.
 
12. Service Ownership
هر سرویس باید مالک محصول، مالک فنی و مالک داده داشته باشد.
 
13. Service Criticality
سرویس‌ها در سه سطح طبقه‌بندی می‌شوند:

Mission Critical
Business Critical
Supporting
14. MVP Services
سرویس‌های MVP:
•	CRM Service
•	Customer Service
•	Opportunity Service
•	Supplier Service
•	Commodity Service
•	Offer Service
•	RFQ Service
•	Trust Service
•	Document Service
•	Workflow Service
•	Notification Service
•	Identity Service
 
15. نتیجه‌گیری
Service Catalog مبنای طراحی نرم‌افزار، API، Microservices، پایگاه داده، DevOps و نقشه توسعه محصول iKIA خواهد بود.
تمام توسعه‌های آینده باید با این کاتالوگ همسو باشند.
 
پایان سند
AP-02_Platform_Service_Catalog_v1.0

