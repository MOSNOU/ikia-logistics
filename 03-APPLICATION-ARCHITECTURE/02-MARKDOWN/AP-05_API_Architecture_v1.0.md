AP-05_API_Architecture_v1.0
معماری API پلتفرم iKIA
Document Code: AP-05
Version: 1.0
Status: Draft
Classification: Application Architecture Document
 
1. مقدمه
APIها ستون فقرات فنی پلتفرم iKIA هستند.
تمام ارتباطات میان:
•	وب‌اپلیکیشن
•	موبایل
•	پورتال شرکا
•	سرویس‌های داخلی
•	سامانه‌های خارجی
•	ERPها
•	بانک‌ها
•	سامانه‌های حاکمیتی
•	سرویس‌های AI
باید از طریق APIهای استاندارد، امن، نسخه‌بندی‌شده و قابل پایش انجام شود.
 
2. هدف سند
هدف این سند تعریف معماری مرجع API برای پلتفرم iKIA است.
این سند مبنای طراحی:
•	API Gateway
•	Backend Services
•	Frontend Integration
•	Partner API Portal
•	Developer Portal
•	External Integrations
•	Mobile Applications
خواهد بود.
 
3. اصول بنیادین API
تمام APIهای iKIA باید بر اساس اصول زیر طراحی شوند:
•	API First
•	Contract First
•	Secure by Design
•	Versioned
•	Observable
•	Backward Compatible
•	Developer Friendly
•	Domain Driven
•	Multi-Tenant Aware
 
4. سبک‌های API
پلتفرم از چند سبک API پشتیبانی می‌کند:

REST API
GraphQL API
Webhook API
Event API
Internal Service API
External Partner API
Batch API
File API

5. REST API
REST سبک اصلی APIهای عمومی و عملیاتی پلتفرم است.
موارد استفاده:
•	CRUD
•	Portal Operations
•	Mobile Operations
•	Partner Integration
 
6. GraphQL API
GraphQL برای تجربه‌های کاربری پیچیده و داشبوردهای ترکیبی استفاده می‌شود.
موارد استفاده:
•	Executive Dashboards
•	CRM Views
•	Analytics Screens
•	Admin Console
 
7. Webhook API
Webhook برای اطلاع‌رسانی رویدادها به شرکای خارجی استفاده می‌شود.
نمونه‌ها:
•	Shipment Status Changed
•	RFQ Awarded
•	Contract Signed
•	Payment Confirmed
 
8. Event API
Event API برای انتشار و مصرف رویدادهای دامنه‌ای میان سرویس‌ها استفاده می‌شود.
 
9. API Gateway
API Gateway نقطه ورود واحد برای تمام APIهای خارجی و داخلی کنترل‌شده است.
 
مسئولیت‌ها
•	Routing
•	Authentication
•	Authorization
•	Rate Limiting
•	Logging
•	Monitoring
•	Caching
•	Request Validation
•	Threat Protection
 
10. API Security Model
امنیت APIها بر اساس چند لایه طراحی می‌شود.
 
Authentication
•	OAuth2
•	OpenID Connect
•	JWT
•	API Key
•	Session Token
 
Authorization
•	RBAC
•	ABAC
•	Tenant Scope
•	Organization Scope
•	Resource Scope
 
Protection
•	Rate Limiting
•	IP Whitelisting
•	Payload Validation
•	WAF
•	Bot Protection
 
11. API Versioning Strategy
نسخه‌بندی APIها الزامی است.
الگوی پیشنهادی:

/api/v1/customers
/api/v1/rfqs
/api/v1/shipments

اصول نسخه‌بندی
•	تغییرات Breaking باید نسخه جدید داشته باشند.
•	نسخه‌های قدیمی باید دوره Deprecation داشته باشند.
•	مستندات نسخه‌ها باید نگهداری شود.
 
12. API Naming Standards
اصول نام‌گذاری:
•	استفاده از اسم جمع
•	استفاده از kebab-case
•	عدم استفاده از فعل در مسیر
•	استفاده از HTTP Method برای عمل
 
نمونه:

GET /api/v1/customers
POST /api/v1/rfqs
GET /api/v1/shipments/{id}
PATCH /api/v1/offers/{id}

13. HTTP Methods
GET     Read
POST    Create
PUT     Replace
PATCH   Update
DELETE  Delete
14. استاندارد پاسخ API
تمام پاسخ‌ها باید ساختار استاندارد داشته باشند.
{
  "data": {},
  "meta": {},
  "errors": []
}
15. استاندارد خطا
{
  "errors": [
    {
      "code": "VALIDATION_ERROR",
      "message": "Invalid input",
      "field": "email"
    }
  ]
}

16. Pagination
برای لیست‌ها الزامی است.

?page=1&page_size=50

17. Filtering
?status=active&type=supplier

18. Sorting
?sort=created_at:desc

19. Idempotency
برای عملیات حساس مالی و تراکنشی، Idempotency Key الزامی است.
Idempotency-Key: unique-request-id

20. Correlation ID
برای رهگیری درخواست‌ها:
X-Correlation-ID

21. API Domain Catalog
 
API-01 Identity API
Purpose
احراز هویت، نشست، نقش‌ها و مجوزها.
Endpoints
POST /api/v1/auth/login
POST /api/v1/auth/logout
POST /api/v1/auth/refresh
GET  /api/v1/me

API-02 Customer API
Purpose
مدیریت مشتریان و سازمان‌ها.
Endpoints
GET    /api/v1/customers
POST   /api/v1/customers
GET    /api/v1/customers/{id}
PATCH  /api/v1/customers/{id}

API-03 CRM API
Purpose
مدیریت Lead، Account، Activity و Pipeline.
Endpoints
GET    /api/v1/leads
POST   /api/v1/leads
PATCH  /api/v1/leads/{id}
POST   /api/v1/leads/{id}/qualify

API-04 Opportunity API
Purpose
مدیریت فرصت‌ها.
Endpoints
GET    /api/v1/opportunities
POST   /api/v1/opportunities
PATCH  /api/v1/opportunities/{id}
POST   /api/v1/opportunities/{id}/assign

API-05 Supplier API
Purpose
مدیریت تأمین‌کنندگان.
Endpoints
GET    /api/v1/suppliers
POST   /api/v1/suppliers
GET    /api/v1/suppliers/{id}
PATCH  /api/v1/suppliers/{id}
POST   /api/v1/suppliers/{id}/approve

API-06 Commodity API
Purpose
مدیریت کالاها، دسته‌بندی و مشخصات فنی.
Endpoints
GET    /api/v1/commodities
POST   /api/v1/commodities
GET    /api/v1/commodities/{id}
PATCH  /api/v1/commodities/{id}
POST   /api/v1/commodities/{id}/approve

API-07 Offer API
Purpose
مدیریت تابلو عرضه.
Endpoints
GET    /api/v1/offers
POST   /api/v1/offers
GET    /api/v1/offers/{id}
PATCH  /api/v1/offers/{id}
POST   /api/v1/offers/{id}/publish

API-08 RFQ API
Purpose
مدیریت درخواست‌های قیمت.
Endpoints

GET    /api/v1/rfqs
POST   /api/v1/rfqs
GET    /api/v1/rfqs/{id}
PATCH  /api/v1/rfqs/{id}
POST   /api/v1/rfqs/{id}/publish
POST   /api/v1/rfqs/{id}/award

API-09 Contract API
Purpose
مدیریت قراردادها.
Endpoints
GET    /api/v1/contracts
POST   /api/v1/contracts
GET    /api/v1/contracts/{id}
POST   /api/v1/contracts/{id}/sign

API-10 Trust API
Purpose
مدیریت احراز هویت، KYB، Trust Score و Reputation.
Endpoints
GET    /api/v1/trust-profiles/{id}
POST   /api/v1/verifications
GET    /api/v1/trust-scores/{id}
POST   /api/v1/trust-events

API-11 Compliance API
Purpose
مدیریت انطباق، Screening و Audit.
Endpoints
POST   /api/v1/compliance/checks
GET    /api/v1/compliance/cases
PATCH  /api/v1/compliance/cases/{id}

API-12 Logistics API
Purpose
مدیریت برنامه حمل و مسیر.
Endpoints
POST   /api/v1/logistics-orders
POST   /api/v1/transport-plans
GET    /api/v1/routes
POST   /api/v1/routes/optimize

API-13 Carrier API
Purpose
مدیریت شرکت‌های حمل، ناوگان و رانندگان.
Endpoints
GET    /api/v1/carriers
POST   /api/v1/carriers
POST   /api/v1/vehicles
POST   /api/v1/drivers

API-14 Shipment API
Purpose
مدیریت محموله، رهگیری و POD.
Endpoints
GET    /api/v1/shipments
POST   /api/v1/shipments
GET    /api/v1/shipments/{id}
POST   /api/v1/shipments/{id}/tracking-events
POST   /api/v1/shipments/{id}/pod

API-15 Settlement API
Purpose
مدیریت صورتحساب و تسویه.
Endpoints
POST   /api/v1/invoices
POST   /api/v1/settlements
POST   /api/v1/payments/confirm

API-16 Escrow API
Purpose
مدیریت Escrow.
Endpoints
POST   /api/v1/escrow-cases
POST   /api/v1/escrow-cases/{id}/hold
POST   /api/v1/escrow-cases/{id}/release

API-17 Claims API
Purpose
مدیریت اختلافات و Claims.
Endpoints
GET    /api/v1/claims
POST   /api/v1/claims
POST   /api/v1/claims/{id}/evidence
POST   /api/v1/claims/{id}/close

API-18 Document API
Purpose
مدیریت اسناد و فایل‌ها.
Endpoints
POST   /api/v1/documents
GET    /api/v1/documents/{id}
POST   /api/v1/documents/{id}/versions
POST   /api/v1/files/upload

API-19 Workflow API
Purpose
مدیریت فرآیندها.
Endpoints
POST   /api/v1/workflows
POST   /api/v1/workflow-instances
POST   /api/v1/tasks/{id}/complete

API-20 Notification API
Purpose
مدیریت اعلان‌ها.
Endpoints
POST   /api/v1/notifications/send
GET    /api/v1/notifications
PATCH  /api/v1/notifications/{id}/read

API-21 AI API
Purpose
ارائه خدمات AI.
Endpoints
POST   /api/v1/ai/copilot/query
POST   /api/v1/ai/documents/generate
POST   /api/v1/ai/recommendations
POST   /api/v1/ai/classify-email

API-22 Analytics API
Purpose
گزارش‌ها، KPIها و داشبوردها.
Endpoints
GET    /api/v1/analytics/kpis
GET    /api/v1/analytics/dashboards/{id}
GET    /api/v1/reports

22. Webhook Catalog
API	Owner
Identity API	Platform Team
CRM API	Commercial Product Team
Supplier API	Supply Chain Product Team
RFQ API	Trade Product Team
Logistics API	Logistics Product Team
Trust API	Trust Product Team
AI API	AI Product Team

24. API Lifecycle
Design
↓
Review
↓
Develop
↓
Test
↓
Publish
↓
Monitor
↓
Improve
↓
Deprecate

25. API Governance
تمام APIها باید:
•	در API Catalog ثبت شوند.
•	OpenAPI Specification داشته باشند.
•	تست امنیتی داشته باشند.
•	مالک مشخص داشته باشند.
•	SLA مشخص داشته باشند.
 
26. Developer Portal
Developer Portal باید شامل:
•	API Documentation
•	Sandbox
•	API Keys
•	Usage Analytics
•	Support
باشد.
 
27. KPIهای API
•	API Availability
•	API Response Time
•	API Error Rate
•	API Adoption
•	API Usage
•	API Latency
•	API Security Incidents
 
28. نتیجه‌گیری
API Architecture پایه اتصال تمام اجزای داخلی و خارجی iKIA است.
بدون API Governance، پلتفرم به مجموعه‌ای از سرویس‌های پراکنده تبدیل خواهد شد.
این سند مرجع رسمی طراحی، توسعه و مدیریت APIهای iKIA است.
 
پایان سند
AP-05_API_Architecture_v1.0

