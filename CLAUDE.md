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

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code (linting)
flutter analyze

# Get dependencies
flutter pub get
```

## Architecture

**Clean Architecture + BLoC** with three layers per feature:

```
lib/
├── core/           # Shared: errors (Either/Failure pattern via dartz), routing (go_router),
│                   #   theme (Material 3), utilities (date formatting, PDF generation), widgets
├── features/
│   ├── auth/       # Firebase Auth (email/password login only)
│   └── transport/  # Transport records CRUD + search + PDF export
├── di/             # GetIt service locator (injection_container.dart)
└── main.dart       # Entry point: Firebase init → DI setup → BLoC providers → MaterialApp.router
```

Each feature follows: `data/` (datasources, models, repository impls) → `domain/` (entities, abstract repos, use cases) → `presentation/` (BLoC, pages).

## Key Patterns

- **Error handling**: `Either<Failure, T>` from dartz — no exceptions propagate from repositories. Failure types: `ServerFailure`, `AuthFailure`, `CacheFailure`.
- **Auto-calculation**: `TransportRecord.create()` and `TripEntry.create()` factory constructors compute totals (totalLoads, totalAmount, balance, amountPerTrip) — never set these manually.
- **DI**: GetIt with lazy singletons for services/repos and factories for BLoCs. All wiring in `di/injection_container.dart`.
- **Routing**: GoRouter with auth-based redirects. Protected routes require `AuthAuthenticated` state.
- **Search**: Client-side filtering (Firestore limitation) on location, vehicle numbers, and transporter names.
- **PDF export**: `PdfGenerator` in `core/utils/pdf_generator.dart` outputs a format matching VRS Enterprise's paper layout.

## Firestore

- **Project**: `vrs-invoice-db`
- **Collection**: `transport_records` (ordered by `date` descending)
- **Field constants**: `core/constants/firestore_constants.dart`

## State Management

Two BLoCs:
- **AuthBloc**: `AuthCheckRequested` → monitors Firebase auth stream; `AuthLoginRequested` / `AuthLogoutRequested`
- **TransportBloc**: Load, Create, Update, Delete, Search, ClearSearch — successful mutations auto-reload the list

## Tech Stack

Flutter (Dart 3.11+), flutter_bloc, go_router, firebase_core/auth/cloud_firestore, dartz, get_it, equatable, pdf + printing, intl
