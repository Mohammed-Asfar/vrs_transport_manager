# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VRS Transport Manager is a **Flutter Windows desktop application** for VRS Enterprises (Madayampakkam) that manages transport trip records. It uses Firebase Firestore as the backend database and Firebase Authentication for login-only access (no registration — users are created manually in Firebase Console).

## Common Commands

```bash
# Run the app (Windows desktop)
flutter run -d windows

# Build for Windows
flutter build windows

# Analyze code (linting)
flutter analyze

# Get dependencies
flutter pub get
```

No test suite exists. The `test/` directory is not present.

## Architecture

**Clean Architecture + BLoC** with three layers per feature:

```
lib/
├── core/           # Shared: errors, routing (go_router), theme, utilities, widgets
├── features/
│   ├── auth/       # Firebase Auth (email/password login only)
│   ├── transport/  # Transport records CRUD + search + PDF export
│   └── reports/    # Date-range reports with transporter/vehicle grouping + PDF export
├── di/             # GetIt service locator (injection_container.dart)
└── main.dart       # Firebase init → DI setup → BLoC providers → MaterialApp.router
```

Each feature follows: `data/` (datasources, models, repository impls) → `domain/` (entities, abstract repos, use cases) → `presentation/` (BLoC, pages, widgets).

**Note:** `firebase_options.dart` is manually maintained (not FlutterFire CLI generated). It contains the Firebase config for project `vrs-transport-db`.

## Key Patterns

- **Error handling**: `Either<Failure, T>` from dartz — no exceptions propagate from repositories. Failure types: `ServerFailure`, `AuthFailure`, `CacheFailure`.
- **Auto-calculation**: `TransportRecord.create()` and `TripEntry.create()` factory constructors compute totals (totalLoads, totalAmount, balance, amountPerTrip) — never set these manually.
- **DI**: GetIt with lazy singletons for services/repos and factories for BLoCs. All wiring in `di/injection_container.dart`.
- **Routing**: GoRouter with auth-based redirects via `_AuthNotifier`. Protected routes require `AuthAuthenticated` state. Routes: `/splash`, `/login`, `/` (dashboard), `/reports`, `/create`, `/edit/:id`, `/detail/:id`. The `/edit/:id` route lazy-loads record data using `GetRecordByIdUseCase`.
- **Real-time updates**: `TransportRepository.watchRecords()` streams live Firestore changes to the UI. TransportBloc handles this without overwriting active search results.
- **Search**: Client-side filtering (Firestore limitation) on location, vehicle numbers, and transporter names.
- **PDF export**: Two generators — `PdfGenerator` for individual records, `ReportPdfGenerator` for aggregated reports. Both use Noto Sans font for rupee symbol (₹) support.

## Firestore

- **Project**: `vrs-transport-db`
- **Collection**: `transport_records` (ordered by `date` descending) — authenticated users have R/W access
- **Collection**: `app_config`, document `version` — authenticated users have read-only access (used for update checking)
- **Field constants**: `core/constants/firestore_constants.dart`

## State Management

Three BLoCs:
- **AuthBloc**: `AuthCheckRequested` → monitors Firebase auth stream (with 3s timeout for Windows C++ SDK); `AuthLoginRequested` / `AuthLogoutRequested`
- **TransportBloc**: Load, Create, Update, Delete, Search, ClearSearch — successful mutations auto-reload the list; subscribes to real-time Firestore stream
- **ReportBloc**: `ReportGenerate` (date range + view mode), `ReportExportPdf`, `ReportReset` — supports transporter-wise and vehicle-wise grouping with proportional diesel/advance allocation. Preset date filters: thisWeek, lastWeek, thisMonth, custom.

## UI Design

macOS-inspired dark theme with Material 3:
- Dark background (`#1E1E1E`), accent blue (`#0A84FF`), surface colors (`#2D2D2D`, `#383838`)
- Flat design: elevation 0, 6-8px border radius
- System font: Segoe UI on Windows (SF Pro equivalent)
- Typography: 11 levels from heading1 (26px) to caption (11px), defined in `app_text_styles.dart`
- Asset: `assets/logo_512.png` (app logo)

## Versioning & Installer

App version is defined in **three places** that must stay in sync:
- `lib/core/utils/app_version.dart` — `AppVersion.currentVersion` (used at runtime)
- `pubspec.yaml` — `version:` field
- `installer.iss` — `AppVersion` and `OutputBaseFilename` (Inno Setup script for Windows installer)

Build the installer: `flutter build windows` then compile `installer.iss` with Inno Setup. Output goes to `installer_output/`.

## In-App Update Checker

`UpdateCheckerService` reads from Firestore `app_config/version` with fields: `latest_version`, `download_url`, `release_notes`, `force_update`. When `latest_version` exceeds `AppVersion.currentVersion` (semantic version comparison), an update dialog is shown. `force_update` prevents dismissal.

## Adding a New Feature

Follow the existing pattern: create `data/`, `domain/`, `presentation/` directories under `features/<name>/`. Then register all new datasources, repositories, use cases, and BLoCs in `di/injection_container.dart` — the app won't see them otherwise. Add the route in `core/router/app_router.dart`.

## Tech Stack

Flutter (Dart 3.11+), flutter_bloc, go_router, firebase_core/auth/cloud_firestore, dartz, get_it, equatable, pdf + printing, intl, url_launcher
