# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VRS Transport Manager is a **Flutter Windows desktop application** for VRS Enterprises (Madayampakkam) that manages transport trip records. It uses Firebase Firestore as the backend database and Firebase Authentication for login-only access (no registration — users are created manually in Firebase Console).

## Common Commands

```bash
# Run the app (Windows desktop)
flutter run -d windows

# Release (from develop branch): bumps version, builds, creates installer, merges to main, uploads to GitHub Releases
# GitHub Actions then updates Firestore with download URL
./scripts/release.sh 1.5.0 "Added new feature X, fixed bug Y"

# Build for Windows
flutter build windows

# Analyze code (linting)
flutter analyze

# Get dependencies
flutter pub get
```

No test suite exists. Do not create a `test/` directory or suggest writing tests unless explicitly asked.

## Architecture

**Clean Architecture + BLoC** with three layers per feature:

```
lib/
├── core/           # Shared: errors, routing (go_router), theme, utilities, widgets
├── features/
│   ├── auth/       # Firebase Auth (email/password login only)
│   ├── transport/  # Transport records CRUD + search + PDF export
│   ├── machinery/  # Machinery records CRUD + search + PDF export (two billing modes)
│   └── reports/    # Date-range reports with transporter/vehicle grouping + PDF export
├── di/             # GetIt service locator (injection_container.dart)
└── main.dart       # Firebase init → DI setup → BLoC providers → MaterialApp.router
```

Each feature follows: `data/` (datasources, models, repository impls) → `domain/` (entities, abstract repos, use cases) → `presentation/` (BLoC, pages, widgets).

**Note:** `firebase_options.dart` is manually maintained (not FlutterFire CLI generated). It contains the Firebase config for project `vrs-transport-db`.

## Key Patterns

- **Error handling**: `Either<Failure, T>` from dartz — no exceptions propagate from repositories. Failure types: `ServerFailure`, `AuthFailure`, `CacheFailure`.
- **Auto-calculation**: `TransportRecord.create()`, `TripEntry.create()`, and `MachineryRecord.create()` factory constructors compute totals (totalLoads, totalAmount, balance, amountPerTrip) — never set these manually.
- **DI**: GetIt with lazy singletons for services/repos and factories for BLoCs. All wiring in `di/injection_container.dart`.
- **Routing**: GoRouter with auth-based redirects via `_AuthNotifier`. Protected routes require `AuthAuthenticated` state. All authenticated routes are wrapped in a `ShellRoute` that provides the persistent sidebar (`MainShell`). Routes: `/splash`, `/login`, `/` (dashboard), `/reports`, `/create`, `/edit/:id`, `/detail/:id`, `/machinery`, `/machinery/create`, `/machinery/edit/:id`, `/machinery/detail/:id`. Edit routes lazy-load record data using their respective `GetRecordByIdUseCase`. Shell routes use `CustomTransitionPage` with a 150ms crossfade (no slide/pop).
- **Real-time updates**: `TransportRepository.watchRecords()` streams live Firestore changes to the UI. TransportBloc handles this without overwriting active search results.
- **Search**: Client-side filtering (Firestore limitation) on location, vehicle numbers, and transporter names.
- **PDF export**: Three generators — `PdfGenerator` for transport records, `MachineryPdfGenerator` for machinery records, `ReportPdfGenerator` for aggregated reports. All use Noto Sans font for rupee symbol (₹) support. `ReportPdfGenerator` has two export modes: **Company** (single continuous table, no financials, KM halved, no transporter names) and **Transporter** (summary page + per-transporter detail pages with full financials).

## Firestore

- **Project**: `vrs-transport-db`
- **Collection**: `transport_records` (ordered by `date` descending) — authenticated users have R/W access
- **Collection**: `machinery_records` (ordered by `date` descending) — authenticated users have R/W access
- **Collection**: `app_config`, document `version` — authenticated users have read-only access (used for update checking)
- **Field constants**: `core/constants/firestore_constants.dart`
- **Transport record fields**: `date` (Timestamp), `location` (String), `trips` (Array of maps: vehicleNo, transporter, chainage, km, ratePerKm, amountPerTrip, noOfLoads), `totalLoads`, `totalAmount`, `diesel`, `advance`, `balance`, `createdAt`, `updatedAt`, `createdBy` (Firebase Auth UID)
- **Security rules**: Only authenticated users can R/W `transport_records` and `machinery_records`; only read `app_config`

## State Management

Four BLoCs:
- **AuthBloc**: `AuthCheckRequested` → monitors Firebase auth stream (with 3s timeout for Windows C++ SDK); `AuthLoginRequested` / `AuthLogoutRequested`
- **TransportBloc**: Load, Create, Update, Delete, Search, ClearSearch — successful mutations auto-reload the list; subscribes to real-time Firestore stream
- **MachineryBloc**: Same pattern as TransportBloc. Supports two billing modes: `monthlyRent` (fixed monthly rate) and `perLoad` (ratePerLoad × totalLoads)
- **ReportBloc**: `ReportGenerate` (date range + view mode), `ReportExportPdf` (with `ExportTarget`: company or transporter), `ReportReset` — supports transporter-wise grouping with proportional diesel/advance allocation. Preset date filters: today, thisWeek, lastWeek, thisMonth, custom.

## UI Design

Dark-only macOS-inspired design system with Material 3:
- **Theme**: Single dark theme in `AppTheme.lightTheme` (named `lightTheme` but actually dark). Background `#1E1E1E`, surface `#2D2D2D`, blue accent `#0A84FF`. Colors defined as static constants in `AppColors`.
- **Left sidebar navigation**: `MainShell` (`core/widgets/main_shell.dart`) wraps authenticated pages via `ShellRoute`. Sidebar background `#252525`.
- Flat design: elevation 0, 6–8px border radius, 0.5px borders
- System font: Segoe UI on Windows
- Typography: color-agnostic styles defined in `app_text_styles.dart`, colors applied at usage site
- Asset: `assets/logo_512.png` (app logo)
- **Shared widgets**: `AppToolbar`, `QuickStatsStrip`, `FormSection`, `FinancialSummaryCard`, `SidebarNavItem`, `AppTextField`, `ConfirmationDialog`, `LoadingOverlay` in `core/widgets/`

## Versioning & Installer

App version is defined in **three places** that must stay in sync:
- `lib/core/utils/app_version.dart` — `AppVersion.currentVersion` (used at runtime)
- `pubspec.yaml` — `version:` field
- `installer.iss` — `AppVersion` and `OutputBaseFilename` (Inno Setup script for Windows installer)

### Automated Release

**Branching**: `develop` (daily work) → merge into `main` (triggers Firestore update).

**Release script** (`scripts/release.sh`): does everything locally + creates the GitHub Release, then GitHub Actions only updates Firestore.

```bash
# Usage (must be on develop branch, no uncommitted changes):
./scripts/release.sh <version> "<release notes>"

# Example:
./scripts/release.sh 1.5.0 "Added company export, fixed dropdown crash"
```

**What the script does:**
1. Updates version in `app_version.dart`, `pubspec.yaml`, `installer.iss`
2. Writes release notes to `RELEASE_NOTES.md`
3. Runs `flutter build windows --release`
4. Compiles Inno Setup installer (requires Inno Setup 6 at `D:/Software/Inno Setup 6/ISCC.exe`)
5. Commits version bump on `develop`, merges `develop` → `main`, pushes both
6. Creates GitHub Release with `.exe` attached via `gh` CLI

`RELEASE_NOTES.md` is auto-generated by the release script — do not edit it manually.

**What GitHub Actions does** (triggered by push to `main`):
- Reads version from `app_version.dart` and `RELEASE_NOTES.md`
- Updates Firestore `app_config/version` with download URL and release notes (sets `force_update: true` by default)
- Runs unconditionally on every push to `main` (no duplicate-version check)

**Prerequisites:**
- `gh` CLI authenticated (`gh auth login`)
- Inno Setup 6 installed at `D:/Software/Inno Setup 6/`
- `FIREBASE_SERVICE_ACCOUNT` secret in GitHub repo settings (Settings → Secrets → Actions). Value = Firebase service account JSON key.

### Manual Build

`flutter build windows` then compile `installer.iss` with Inno Setup. Output goes to `installer_output/`.

## In-App Update Checker

`UpdateCheckerService` reads from Firestore `app_config/version` with fields: `latest_version`, `download_url`, `release_notes`, `force_update`, `updated_at`. When `latest_version` exceeds `AppVersion.currentVersion` (semantic version comparison), an update dialog is shown. `force_update` prevents dismissal.

## Adding a New Feature

Follow the existing pattern: create `data/`, `domain/`, `presentation/` directories under `features/<name>/`. Then register all new datasources, repositories, use cases, and BLoCs in `di/injection_container.dart` — the app won't see them otherwise. Add the route in `core/router/app_router.dart`.

## Important Gotchas

- `AppTheme.lightTheme` is misleadingly named — it's actually the dark theme. Don't create a second theme.
- `firebase_options.dart` is hand-written, not generated by FlutterFire CLI. Edit it directly if Firebase config changes.
- `force_update` in Firestore `app_config/version` is hardcoded to `true` in the GitHub Actions workflow. To make updates dismissable, manually set it to `false` in Firestore Console after release.
- The `TransportBloc` subscribes to a real-time Firestore stream. When adding new events that modify state, ensure they don't overwrite active search results (check `_isSearchActive` pattern).
- Dart SDK constraint is `^3.11.0` (not Flutter SDK — the Flutter SDK version follows from this).

## Tech Stack

Flutter (Dart 3.11+), flutter_bloc, go_router, firebase_core/auth/cloud_firestore, dartz, get_it, equatable, pdf + printing, intl, url_launcher, shared_preferences
