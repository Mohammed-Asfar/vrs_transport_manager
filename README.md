# VRS Transport Manager

A Flutter Windows desktop application for **VRS Enterprises, Madayampakkam** to manage transport and machinery records.

> **Developer:** Asfar
> **License:** Private — VRS Enterprises

---

## Features

- **Authentication** — Firebase email/password login (no self-registration; users are created manually in Firebase Console)
- **Transport Records** — Full CRUD for daily transport records, each containing multiple trip entries
- **Machinery Records** — Full CRUD for machinery records with two billing modes: monthly rent (fixed rate) and per-load (ratePerLoad × totalLoads)
- **Reports** — Date-range reports with transporter-wise and vehicle-wise grouping, proportional diesel/advance allocation, and PDF export
- **Auto-Calculations** — `amountPerTrip = km * ratePerKm`, `totalAmount`, `totalLoads`, and `balance = totalAmount - diesel - advance` are computed automatically
- **Search** — Client-side filtering by vehicle number, transporter name, or location
- **PDF Export** — Generate PDFs for transport records, machinery records, and aggregated reports (with Noto Sans for rupee symbol support)
- **In-App Updates** — Reads version info from Firestore (`app_config/version`) and prompts users to download new releases

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.11+ (Windows Desktop) |
| State Management | flutter_bloc |
| Backend | Cloud Firestore |
| Authentication | Firebase Auth |
| Dependency Injection | get_it |
| Routing | go_router with auth guards |
| Error Handling | dartz (`Either<Failure, T>`) |
| PDF | pdf + printing |
| Other | equatable, intl, url_launcher, shared_preferences |

## Architecture

Clean Architecture with BLoC pattern. Each feature is split into three layers:

```
lib/
├── core/                     # Shared infrastructure
│   ├── constants/            # Firestore field name constants
│   ├── errors/               # Exception & Failure types
│   ├── router/               # GoRouter config with auth redirect
│   ├── services/             # Update checker service
│   ├── theme/                # Dark theme (macOS-inspired), colors, typography
│   ├── utils/                # Date formatting, PDF generation, app version
│   └── widgets/              # Reusable UI components (MainShell sidebar, toolbar, etc.)
├── features/
│   ├── auth/                 # data → domain → presentation
│   ├── transport/            # data → domain → presentation
│   ├── machinery/            # data → domain → presentation
│   └── reports/              # data → domain → presentation
├── di/                       # GetIt service locator wiring
├── firebase_options.dart
└── main.dart                 # Firebase init → DI → BLoC providers → MaterialApp.router
```

## Firestore

**Project:** `vrs-transport-db`

### `transport_records` collection

| Field | Type | Description |
|---|---|---|
| `date` | Timestamp | Record date (collection ordered by date desc) |
| `location` | String | Work site location |
| `trips` | Array | List of trip entry maps (vehicleNo, transporter, chainage, km, ratePerKm, amountPerTrip, noOfLoads) |
| `totalLoads` | int | Sum of all trip loads |
| `totalAmount` | double | Sum of (amountPerTrip * noOfLoads) across trips |
| `diesel` | double | Diesel expense |
| `advance` | double | Advance payment |
| `balance` | double | totalAmount - diesel - advance |
| `createdAt` | Timestamp | Creation timestamp |
| `updatedAt` | Timestamp | Last update timestamp |
| `createdBy` | String | Firebase Auth UID |

### `machinery_records` collection

Ordered by `date` descending. Supports two billing modes: `monthlyRent` (fixed monthly rate) and `perLoad` (ratePerLoad × totalLoads).

### `app_config` collection

Document `version` with fields: `latest_version`, `download_url`, `release_notes`, `force_update`.

## Routes

| Path | Page | Auth Required |
|---|---|---|
| `/splash` | Loading spinner | No |
| `/login` | Login page | No |
| `/` | Dashboard (transport record list) | Yes |
| `/reports` | Date-range reports | Yes |
| `/create` | New transport record form | Yes |
| `/edit/:id` | Edit transport record form | Yes |
| `/detail/:id` | Transport record detail + PDF export | Yes |
| `/machinery` | Machinery record list | Yes |
| `/machinery/create` | New machinery record form | Yes |
| `/machinery/edit/:id` | Edit machinery record form | Yes |
| `/machinery/detail/:id` | Machinery record detail + PDF export | Yes |

## Getting Started

### Prerequisites

- Flutter SDK ^3.11.0
- A Firebase project with Email/Password Authentication enabled
- User accounts created in Firebase Console (no registration flow in the app)

### Run

```bash
flutter pub get
flutter run -d windows
```

### Build

```bash
flutter build windows
```

### Build Installer

After building, compile `installer.iss` with [Inno Setup](https://jrsoftware.org/isinfo.php). The installer is output to `installer_output/`.

## Firestore Rules

Only authenticated users can read/write `transport_records` and `machinery_records`. Only authenticated users can read `app_config`.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /transport_records/{document=**} {
      allow read, write: if request.auth != null;
    }
    match /machinery_records/{document=**} {
      allow read, write: if request.auth != null;
    }
    match /app_config/{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```
