# VRS Transport Manager

A Flutter Windows desktop application for **VRS Enterprises, Madayampakkam** to manage transport trip records with Firestore backend, Firebase Authentication, full CRUD operations, search, and PDF export.

> **Developer:** Asfar

---

## Features

- **Firebase Email/Password Authentication** — Login-only (no registration)
- **Transport Record Management** — Full CRUD (Create, Read, Update, Delete)
- **Search** — Search by vehicle number, transporter, or location
- **PDF Export** — Generate and download PDF matching the original VRS format
- **Auto-Calculations** — Amount per trip, total loads, total amount, and balance
- **Enterprise Architecture** — Clean Architecture + BLoC + SOLID principles

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Windows Desktop) |
| State Management | `flutter_bloc` (BLoC pattern) |
| Backend | Firebase Firestore (`vrs-invoice-db` project) |
| Authentication | Firebase Email/Password Auth |
| DI | `get_it` (Service Locator) |
| Routing | `go_router` with auth guards |
| Error Handling | `dartz` (Either pattern) |
| PDF | `pdf` + `printing` |

## Architecture

```
lib/
├── core/                     # Shared infrastructure
│   ├── constants/            # Firestore field constants
│   ├── errors/               # Exceptions & Failures
│   ├── router/               # GoRouter config with auth
│   ├── theme/                # Colors, Theme, Typography
│   ├── utils/                # Date formatter, PDF generator
│   └── widgets/              # Reusable widgets
├── features/
│   ├── auth/                 # Authentication feature
│   │   ├── data/             # Datasource + Repository impl
│   │   ├── domain/           # Entity, Repository, Use Cases
│   │   └── presentation/     # BLoC + Login page
│   └── transport/            # Transport records feature
│       ├── data/             # Model, Datasource, Repository impl
│       ├── domain/           # Entities, Repository, Use Cases
│       └── presentation/     # BLoC + Dashboard, Form, Detail pages
├── di/                       # Dependency injection container
├── firebase_options.dart     # Firebase configuration
└── main.dart                 # App entry point
```

## Firestore Collection

**Collection:** `transport_records`

Each document contains: date, location, trips (array), totalLoads, totalAmount, diesel, advance, balance, timestamps, and createdBy user ID.

## Getting Started

### Prerequisites
- Flutter SDK (^3.11.0)
- Firebase project with Email/Password Auth enabled
- User accounts created in Firebase Console

### Run
```bash
flutter pub get
flutter run -d windows
```

### Build
```bash
flutter build windows
```

## License

Private — VRS Enterprises
