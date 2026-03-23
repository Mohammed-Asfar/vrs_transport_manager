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
- **PDF export**: Three generators — `PdfGenerator` for transport records, `MachineryPdfGenerator` for machinery records, `ReportPdfGenerator` for aggregated reports. All use Noto Sans font for rupee symbol (₹) support.

## Firestore

- **Project**: `vrs-transport-db`
- **Collection**: `transport_records` (ordered by `date` descending) — authenticated users have R/W access
- **Collection**: `machinery_records` (ordered by `date` descending) — authenticated users have R/W access
- **Collection**: `app_config`, document `version` — authenticated users have read-only access (used for update checking)
- **Field constants**: `core/constants/firestore_constants.dart`

## State Management

Four BLoCs:
- **AuthBloc**: `AuthCheckRequested` → monitors Firebase auth stream (with 3s timeout for Windows C++ SDK); `AuthLoginRequested` / `AuthLogoutRequested`
- **TransportBloc**: Load, Create, Update, Delete, Search, ClearSearch — successful mutations auto-reload the list; subscribes to real-time Firestore stream
- **MachineryBloc**: Same pattern as TransportBloc. Supports two billing modes: `monthlyRent` (fixed monthly rate) and `perLoad` (ratePerLoad × totalLoads)
- **ReportBloc**: `ReportGenerate` (date range + view mode), `ReportExportPdf`, `ReportReset` — supports transporter-wise and vehicle-wise grouping with proportional diesel/advance allocation. Preset date filters: thisWeek, lastWeek, thisMonth, custom.

## UI Design

Warm professional design system (Slack/Figma-inspired) with Material 3, supporting **light + dark modes**:
- **Theme system**: `AppColorScheme` (`ThemeExtension`) with semantic tokens. Access via `AppColors.of(context)`. Light theme (warm cream `#FAF8F5`) and dark theme (warm dark `#1C1B1A`). Teal accent (`#0D9488`).
- **Theme persistence**: `shared_preferences` stores theme choice. Toggle in sidebar. `themeModeNotifier` (global `ValueNotifier<ThemeMode>`) in `main.dart`.
- **Left sidebar navigation** (220px): `MainShell` (`core/widgets/main_shell.dart`) wraps authenticated pages. `SidebarNavItem` with 3px teal left indicator bar for active state. Includes theme toggle (sun/moon) above Sign Out.
- **Spacing**: `AppSpacing` constants — 8px border radius (small), 12px (medium/cards), 16px (large/dialogs). Toolbar 56px, table rows 48px, buttons 36px/32px.
- Flat design: elevation 0, warm colors
- System font: Segoe UI on Windows
- Typography: 11 levels from heading1 (26px) to caption (11px), color-agnostic (defined in `app_text_styles.dart`, colors applied at usage site)
- Asset: `assets/logo_512.png` (app logo)
- **Shared widgets**: `AppToolbar`, `QuickStatsStrip`, `FormSection`, `FinancialSummaryCard`, `SidebarNavItem` in `core/widgets/`

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

Flutter (Dart 3.11+), flutter_bloc, go_router, firebase_core/auth/cloud_firestore, dartz, get_it, equatable, pdf + printing, intl, url_launcher, shared_preferences
