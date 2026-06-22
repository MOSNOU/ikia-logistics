DA-02_Master_Data_Management_Architecture_v1.0
معماری مدیریت داده‌های مرجع پلتفرم iKIA
Document Code: DA-02
Version: 1.0
Status: Draft
Classification: Data Architecture Document
 
1. مقدمه
مدیریت داده‌های مرجع یا Master Data Management یکی از ارکان اصلی معماری داده در پلتفرم iKIA است.
پلتفرم iKIA با مجموعه‌ای وسیع از بازیگران، کالاها، شرکت‌ها، کاربران، ناوگان، مکان‌ها، اسناد، قراردادها و تراکنش‌ها کار می‌کند.
اگر داده‌های مرجع به‌درستی طراحی و کنترل نشوند، کل پلتفرم دچار مشکلات زیر خواهد شد:
•	تکرار داده
•	ناسازگاری داده
•	خطای عملیاتی
•	ضعف اعتماد
•	ضعف گزارش‌گیری
•	ضعف هوش مصنوعی
•	ضعف تصمیم‌گیری مدیریتی
 
2. هدف سند
هدف این سند تعریف معماری مدیریت داده‌های مرجع iKIA است.
این سند مشخص می‌کند:
•	چه داده‌هایی Master Data هستند.
•	مالک هر Master Data کیست.
•	Golden Record چگونه ساخته می‌شود.
•	کیفیت داده چگونه کنترل می‌شود.
•	تغییرات داده چگونه مدیریت می‌شود.
•	نقش Data Owner و Data Steward چیست.
•	داده‌های مرجع چگونه در AI و Analytics استفاده می‌شوند.
 
3. اصول MDM
معماری MDM در iKIA بر اساس اصول زیر طراحی می‌شود:
Single Source of Truth
Golden Record
Data Ownership
Data Stewardship
Data Quality by Design
Approval Workflow
Auditability
Versioning
AI Ready Data

4. دامنه‌های اصلی Master Data
Master Data در iKIA شامل دامنه‌های زیر است:

Customer Master
Organization Master
Supplier Master
Commodity Master
Carrier Master
Vehicle Master
Driver Master
Location Master
User Master
Role Master
Reference Data Master

5. Customer Master
تعریف
Customer Master شامل اطلاعات پایه مشتریان حقیقی و حقوقی پلتفرم است.
داده‌های اصلی
•	Customer ID
•	Customer Type
•	Legal Name
•	Commercial Name
•	National ID
•	Tax ID
•	Registration Number
•	Contact Information
•	Address
•	Status
•	Trust Level
مالک داده
Customer Domain
مصرف‌کنندگان
•	CRM
•	RFQ
•	Contract
•	Settlement
•	Analytics
•	AI
 
6. Organization Master
تعریف
Organization Master ساختار شرکت‌ها، شعب، واحدهای سازمانی و ارتباطات سازمانی را نگهداری می‌کند.
داده‌های اصلی
•	Organization ID
•	Parent Organization
•	Branch
•	Department
•	Legal Entity
•	Business Unit
•	Organization Type
•	Status
مالک داده
Organization Domain
 
7. Supplier Master
تعریف
Supplier Master مرجع اصلی اطلاعات تأمین‌کنندگان است.
داده‌های اصلی
•	Supplier ID
•	Organization ID
•	Supplier Type
•	Product Categories
•	Capabilities
•	Countries Served
•	Certificates
•	Compliance Status
•	Trust Score
•	Performance Metrics
•	Approved Commodities
مالک داده
Supplier Management Domain
مصرف‌کنندگان
•	Offer Board
•	RFQ Engine
•	Trust Engine
•	Commodity Platform
•	AI Services
 
8. Commodity Master
تعریف
Commodity Master یکی از مهم‌ترین Master Dataهای iKIA است.
این دامنه مرجع اصلی کالاها، دسته‌بندی‌ها، کدها، مشخصات فنی، اسناد و اطلاعات استاندارد کالایی است.
 
ساختار Commodity Master
Commodity Domain
    ├── Commodity Category
    ├── Commodity Family
    ├── Commodity Group
    ├── Product
    ├── Product Grade
    ├── Specification
    ├── Product Code
    ├── HS Code
    ├── UN Code
    ├── MSDS
    ├── TDS
    └── Product Datasheet
داده‌های اصلی
•	Commodity ID
•	Commodity Name
•	Commodity Category
•	Commodity Family
•	Internal Product Code
•	HS Code
•	UN Code
•	CAS Number
•	Grade
•	Specification
•	Unit of Measure
•	Packaging Type
•	Storage Requirement
•	Safety Classification
 
مالک داده
Commodity Management Domain
مصرف‌کنندگان
•	Supplier Platform
•	Offer Board
•	RFQ Engine
•	Contract Platform
•	Document Engine
•	AI Document Generator
•	Analytics
 
9. Commodity Coding Strategy
برای کالاها باید یک سیستم کدینگ داخلی استاندارد تعریف شود.
کد کالا باید بتواند موارد زیر را نشان دهد:
Category
Family
Product
Grade
Packaging
Specification Version

نمونه ساختار کد
IKIA-COM-CAT-FAM-PROD-GRD-V01

10. Technical Specification Master
برای هر کالا باید مشخصات فنی استاندارد تعریف شود.
نمونه داده‌ها
•	Density
•	Viscosity
•	Flash Point
•	Purity
•	Moisture
•	Sulfur Content
•	Particle Size
•	Melting Point
•	Boiling Point
 
11. Document Master
اسناد وابسته به Master Data شامل:
•	MSDS
•	TDS
•	Product Datasheet
•	Certificate
•	Inspection Report
•	Product Images
•	Technical Attachments
 
12. Carrier Master
تعریف
Carrier Master مرجع اطلاعات شرکت‌های حمل و ارائه‌دهندگان خدمات لجستیکی است.
داده‌های اصلی
•	Carrier ID
•	Legal Name
•	License Number
•	Transport Modes
•	Fleet Size
•	Coverage Area
•	Insurance Status
•	Trust Score
•	Performance Score
 
13. Vehicle Master
تعریف
Vehicle Master مرجع ناوگان حمل است.
داده‌های اصلی
•	Vehicle ID
•	Carrier ID
•	Plate Number
•	Vehicle Type
•	Capacity
•	Tank Type
•	License
•	Insurance
•	Status
 
14. Driver Master
تعریف
Driver Master مرجع اطلاعات رانندگان است.
داده‌های اصلی
•	Driver ID
•	Carrier ID
•	License Number
•	Identity Status
•	Performance Score
•	Status
 
15. Location Master
تعریف
Location Master مرجع مکان‌ها، بنادر، مرزها، انبارها، پایانه‌ها و نقاط لجستیکی است.
انواع مکان
•	Country
•	Province
•	City
•	Port
•	Border
•	Warehouse
•	Terminal
•	Free Zone
•	Industrial Zone
•	Loading Point
•	Delivery Point
 
16. User Master
تعریف
User Master مرجع کاربران پلتفرم است.
داده‌های اصلی
•	User ID
•	Name
•	Email
•	Mobile
•	Organization
•	Role
•	Status
•	MFA Status
 
17. Role Master
تعریف
Role Master نقش‌های امنیتی و عملیاتی را نگهداری می‌کند.
نمونه نقش‌ها
•	Platform Admin
•	Organization Admin
•	Supplier User
•	Buyer User
•	Carrier User
•	Finance User
•	Compliance Officer
•	Trust Officer
•	Auditor
 
18. Reference Data Master
Reference Data شامل داده‌های استاندارد و کم‌تغییر است.
نمونه‌ها
•	Countries
•	Currencies
•	Units of Measure
•	Incoterms
•	HS Codes
•	Workflow States
•	Trust Levels
•	Risk Levels
•	Transport Modes
•	Packaging Types
 
19. Golden Record Strategy
هدف Golden Record ایجاد معتبرترین نسخه هر رکورد است.
اصول
•	شناسایی رکوردهای تکراری
•	ادغام رکوردهای مشابه
•	حفظ منبع داده معتبر
•	ثبت تاریخچه تغییرات
•	امکان بازگشت به نسخه قبلی
 
20. Duplicate Detection
سیستم باید بتواند رکوردهای تکراری را شناسایی کند.
معیارها
•	نام مشابه
•	شناسه ملی
•	شماره ثبت
•	شماره مالیاتی
•	آدرس
•	شماره تماس
•	ایمیل
•	کد کالا
•	HS Code
 
21. Survivorship Rules
در صورت وجود داده‌های متناقض، قانون بقا مشخص می‌کند کدام مقدار معتبر است.
اولویت منابع
Verified Government Source
↓
Approved Internal Record
↓
Trusted Partner Source
↓
User Submitted Data
↓
AI Extracted Data


22. Data Stewardship Model
هر دامنه Master Data باید Data Steward داشته باشد.
وظایف Data Steward
•	بررسی کیفیت داده
•	تأیید تغییرات حساس
•	رسیدگی به رکوردهای تکراری
•	مدیریت خطاهای داده
•	تأیید Golden Record
 
23. Data Governance Roles
Data Owner
مسئول نهایی سیاست و ارزش داده.
Data Steward
مسئول کیفیت و صحت داده.
Data Custodian
مسئول نگهداری فنی داده.
Data Consumer
استفاده‌کننده داده.
 
24. Master Data Lifecycle
Create
↓
Validate
↓
Approve
↓
Publish
↓
Use
↓
Update
↓
Archive
↓
Retire

25. Approval Workflow
تغییرات حساس در Master Data باید Workflow داشته باشند.
نمونه موارد نیازمند تأیید
•	ایجاد Supplier
•	تغییر Trust Status
•	ایجاد Commodity جدید
•	تغییر HS Code
•	تغییر اطلاعات مالی
•	تغییر وضعیت Carrier
 
26. Data Quality Model
ابعاد کیفیت داده:

Completeness
Accuracy
Consistency
Timeliness
Validity
Uniqueness
Integrity
27. Data Quality Rules
Customer
•	شناسه ملی نباید تکراری باشد.
•	شماره موبایل باید معتبر باشد.
•	ایمیل باید قالب معتبر داشته باشد.
Supplier
•	مدارک حقوقی باید تکمیل باشد.
•	وضعیت KYB باید مشخص باشد.
Commodity
•	دسته‌بندی باید مشخص باشد.
•	واحد اندازه‌گیری باید استاندارد باشد.
•	کد کالا باید یکتا باشد.
Location
•	کشور، شهر و مختصات باید معتبر باشند.
 
28. MDM Platform Capabilities
پلتفرم MDM باید قابلیت‌های زیر را داشته باشد:
•	Master Data Registry
•	Golden Record Management
•	Duplicate Detection
•	Data Quality Rules
•	Approval Workflow
•	Audit Trail
•	Versioning
•	Data Steward Dashboard
•	API Access
 
29. MDM API Architecture
تمام Master Dataها باید API داشته باشند.
نمونه APIها
GET /api/v1/master/customers
POST /api/v1/master/suppliers
GET /api/v1/master/commodities
PATCH /api/v1/master/locations/{id}

GET /api/v1/master/customers
POST /api/v1/master/suppliers
GET /api/v1/master/commodities
PATCH /api/v1/master/locations/{id}

30. AI and MDM
AI در MDM نقش کمکی دارد.
کاربردها
•	تشخیص رکورد تکراری
•	پیشنهاد دسته‌بندی کالا
•	استخراج مشخصات فنی
•	تکمیل پروفایل تأمین‌کننده
•	پیشنهاد HS Code
 
محدودیت
AI نباید بدون تأیید انسانی Master Data حساس را نهایی کند.
 
31. MDM and Knowledge Graph
Master Data پایه Knowledge Graph آینده iKIA است.
گره‌های اصلی Knowledge Graph:
Organization
Supplier
Commodity
Offer
RFQ
Contract
Shipment
Location
Trust Profile

32. Master Data Ownership Matrix
Master Data	Owner	Steward
Customer	Customer Domain	CRM Data Steward
Organization	Organization Domain	Enterprise Data Steward
Supplier	Supplier Domain	Supplier Data Steward
Commodity	Commodity Domain	Commodity Data Steward
Carrier	Logistics Domain	Logistics Data Steward
Location	Data Governance	Location Data Steward
User	IAM Domain	Security Steward
Reference Data	Data Governance	Reference Data Steward

33. KPIهای MDM
•	Duplicate Rate
•	Golden Record Accuracy
•	Data Completeness
•	Data Quality Score
•	Approval Cycle Time
•	Master Data Error Rate
•	Stewardship Backlog
 
34. Roadmap
Phase 1
•	Commodity Master
•	Supplier Master
•	Customer Master
•	Organization Master
 
Phase 2
•	Carrier Master
•	Location Master
•	Vehicle Master
•	Driver Master
 
Phase 3
•	Golden Record Engine
•	AI-assisted MDM
•	Knowledge Graph Integration
 
35. نتیجه‌گیری
Master Data Management ستون فقرات داده‌ای iKIA است.
بدون MDM، هیچ Trust Engine، AI Engine، RFQ Engine، Offer Board، Analytics Platform یا Knowledge Graph قابل اتکا نخواهد بود.
 
پایان سند

