# CC-02_Repository_Bootstrap_Prompt_v1.0

# iKIA Repository Bootstrap Prompt

## Mission

Build only the foundation repository for the iKIA Logistics Platform.

Do not build full business modules yet.

The goal of this step is to create a clean, scalable, production-ready foundation for future implementation.

## Tech Stack

Use:

- Next.js 15+
- TypeScript
- TailwindCSS
- shadcn/ui
- Supabase
- PostgreSQL
- RTL support
- Persian-first UI

## Core Requirements

Create:

- Clean project structure
- App Router architecture
- Supabase client setup
- Environment variable structure
- Authentication foundation
- RBAC-ready structure
- RLS-ready architecture
- Domain folder structure
- Shared UI components
- Layout system
- Admin dashboard shell
- Buyer portal shell
- Supplier portal shell
- Carrier portal shell

## Do Not Build Yet

Do not implement:

- Full RFQ engine
- Full offer board
- Full contract engine
- Full logistics execution
- Full AI copilot
- Full analytics
- Full integrations

Only create the foundation.

## Required Folder Structure

Create a scalable structure similar to:

```text
src/
  app/
    (public)/
    (auth)/
    (dashboard)/
    admin/
    buyer/
    supplier/
    carrier/
  components/
    ui/
    layout/
    navigation/
    forms/
    data-display/
  lib/
    supabase/
    auth/
    permissions/
    config/
    utils/
  domains/
    identity/
    organization/
    supplier/
    commodity/
    rfq/
    offer/
    contract/
    logistics/
    finance/
    knowledge/
    ai/
    analytics/
    integration/
  types/
  hooks/
  styles/
Pages to Create

Create minimal shell pages:

* Home page
* Login page
* Admin dashboard
* Buyer dashboard
* Supplier dashboard
* Carrier dashboard
* Unauthorized page
* Not found page

Layout Requirements

Implement:

* Persian-first RTL layout
* English-ready structure
* Responsive layout
* Sidebar navigation
* Top navigation
* Dashboard cards
* Professional enterprise UI

Supabase Requirements

Create:

* Supabase browser client
* Supabase server client
* Supabase middleware foundation
* Auth helper functions
* Session helper
* User profile type
* Role type
* Permission type

RBAC Foundation

Create role constants:

* platform_admin
* organization_admin
* supplier_admin
* buyer_admin
* carrier_admin
* compliance_officer
* finance_officer
* operations_user
* readonly_user

Create permission helpers but do not implement full policies yet.

Environment Variables

Create .env.example with:
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_APP_URL=
OPENAI_API_KEY=
Quality Requirements

Code must be:

* Type-safe
* Clean
* Modular
* Production-ready
* Mobile responsive
* RTL compatible
* Easy to extend

Output Required

At the end, report:

1. Files created
2. Files modified
3. Folder structure
4. How to run locally
5. Next recommended step

Success Criteria

The repository foundation is successful when:

* App runs locally
* Layout renders correctly
* Supabase client is configured
* Auth structure exists
* Domain folders exist
* Dashboard shells exist
* No business-heavy modules are prematurely implemented

END