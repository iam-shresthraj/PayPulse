# PayPulse — Multi-Tenant Inventory & Invoicing System

PayPulse is a premium, modern, multi-tenant enterprise resource planning (ERP), inventory management, and tax-compliant invoicing software designed for retail merchants. The initial application implementation is customized for high-end retail jewellery businesses (e.g. **Swarnayan Jewellers**).

Built using **Flutter** (supporting Android mobile & Web deployments) and backed by **Supabase** (Postgres DB, RLS multi-tenancy, Realtime changes, and Auth), it features a premium glassmorphic dark user interface tailored for modern business environments.

---

## 🚀 Key Features

*   **Multi-Tenancy Scoping:** Dedicated company partitions secured via PostgreSQL Row-Level Security (RLS) policies.
*   **Code-Based Registration:** Clean, role-based user onboarding (`STAFF`, `MANAGER`, `OWNER`) using single-use 8-character invitation codes with automatic rotation upon user review.
*   **Jewellery Billing Engine:** Supports tracking gross weight, stone weight, net weight, daily gold/silver rates (per gram), and making charges (Fixed, Per Gram, or Percentage).
*   **Old Gold Trade-Ins:** Programmatically deducts trade-in gold values from the invoice total based on weight and purity values.
*   **Automatic Tax Compliance:** Computes intra-state (Bihar) CGST (1.5%) + SGST (1.5%) or inter-state IGST (3%) automatically.
*   **Multi-Channel Payments:** split payment values across Cash, UPI, and Card. Tracks outstanding balances.
*   **Invoice PDFs & QR Codes:** Generates print-ready PDFs and embeds dynamic feedback QR codes.
*   **WhatsApp Billing Integration:** Seamless sharing of billing details using pre-formatted templates launched through WhatsApp API links.
*   **Super Admin Control Panel:** Allows platform admins to approve businesses, rotate registration codes, manage global branding, and publish Android OTA app releases with automatic broadcast notifications.

---

## 🛠️ Technology Stack

*   **Frontend Client:** Flutter SDK (Dart)
*   **Database & API Backend:** Supabase (PostgreSQL)
*   **State Management:** Flutter Riverpod (v2)
*   **Navigation / Routing:** GoRouter (v14)
*   **Theme / Styling:** Custom Premium Glassmorphic Design System (Obsidian Amber layout structure with PayPulse Red branding)
*   **Charts & Visual Analytics:** FL Chart
*   **PDF Document Generator:** Printing & PDF packages
*   **Hosting / Web Deployment:** Vercel

---

## 📂 Project Architecture

### Folder Structure
```
├── setup_schema.sql                  # Initial database tables setup
├── supabase_*.sql                    # Database migrations, RLS, functions, and triggers
├── build.sh                          # Vercel CI/CD build script
├── vercel.json                       # Routing rewrite configuration for Vercel SPA routing
└── swarnayan_flutter/                # Core Flutter client project workspace
    ├── assets/                       # Branding images, icons, and logos
    ├── lib/
    │   ├── core/                     # Shared services, themes, and global widgets
    │   │   ├── network/              # Supabase API connectors
    │   │   ├── router/               # Navigation configurations and auth gates
    │   │   ├── theme/                # Typography, spacing, and colors
    │   │   ├── utils/                # WhatsApp, PDF helpers, and formatters
    │   │   └── widgets/              # Reusable glassmorphic UI elements
    │   ├── features/                 # Modular verticals (auth, billing, products, admin, reports)
    │   ├── models/                   # JSON serializable data models
    │   └── main.dart                 # Application entry point
    └── pubspec.yaml                  # Project dependencies and configurations
```

---

## 💾 Database Schema

The database relies on PostgreSQL Row-Level Security policies to partition data across companies.

```
                  +-------------------+
                  |     COMPANIES     |
                  +-------------------+
                            |
         +------------------+------------------+
         |                                     |
+-----------------+                   +------------------+
|    PROFILES     |                   | INVOICES / ITEMS |
+-----------------+                   +------------------+
         |                                     |
+--------------------+                +------------------+
| NOTIFICATION_READS |                |    CUSTOMERS     |
+--------------------+                +------------------+
```

### Main Tables
*   `public.companies`: Registers business tenants and their active invitation codes.
*   `public.profiles`: Stores employee details, access permissions, and approval states.
*   `public.company_settings`: Configures custom invoice sequences, terms, and billing prefixes.
*   `public.customers`: Tracks customer details, purchases, and visit dates.
*   `public.products`: Tracks stock units, HUIDs, weights, and categories.
*   `public.invoices`: Houses transaction records, payment status, items list, and a Base64 copy of the PDF.

---

## ⚙️ Development Setup

### Prerequisites
*   Flutter SDK (stable branch)
*   Dart SDK

### 1. Installation
Change directory to the Flutter workspace and retrieve Dart dependencies:
```bash
cd swarnayan_flutter
flutter pub get
```

### 2. Generate Serialized Code
Generate code for Freeze models:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run Locally
Run the Flutter dev environment (Android emulator, Web browser, or Desktop runner):
```bash
flutter run
```

### 4. Build Production Releases
*   **Android APK:**
    ```bash
    flutter build apk --release
    ```
*   **Web Build:**
    ```bash
    flutter build web --release
    ```

---

## 🌐 Web Deployment (Vercel)

The project includes an automation script `build.sh` that clones and runs Flutter in clean CI environments:
1.  Vercel clones the repository and runs `build.sh`.
2.  `build.sh` downloads the stable Flutter SDK and compiles the web project (`flutter build web --release`).
3.  `vercel.json` rewrites all web requests back to `/index.html` to support client-side GoRouter navigation without encountering 404 errors on refreshes.
