# Plan: Tax Invoice Feature

> Source PRD: GitHub Issue #1 — "Tax Invoice Feature — Generate GST-compliant invoices with PDF export"

## Architectural decisions

Durable decisions that apply across all phases:

- **Routes**: `/invoices` (list), `/invoices/create` (form), `/invoices/edit/:id` (form), `/invoices/detail/:id` (detail + PDF), `/settings` (company profile)
- **Firestore collections**: `invoices` (ordered by `invoiceDate` desc), `clients`, `company_profile` (single document), `app_config/invoice_counter` (serial tracking)
- **Key entities**: `InvoiceRecord` (with nested `InvoiceSection` and `InvoiceLineItem`), `Client`, `CompanyProfile`
- **Auto-calculation**: All computed fields (line item totals, total value, tax amounts, sub total, recoveries, total invoice value, amount in words) are derived in `InvoiceRecord.create()` factory constructor. Never set these manually.
- **Tax mode**: CGST+SGST (intra-state, default) or IGST (inter-state). All three percentages stored; mode is derived from values (IGST > 0 means inter-state).
- **Client denormalization**: Client data is copied inline into the invoice document at save time. Existing invoices are not affected by later client edits.
- **Invoice number format**: `VRS-{MMM}-{YYYY}-{NNN}` — auto-generated, user-editable. Counter per month in `app_config/invoice_counter`.
- **Image storage**: Logo and signature stored as base64 strings in `company_profile` Firestore document. Compressed to max 300x300px, 80% JPEG quality before storage.
- **Sidebar order**: Transport, Machinery, Reports, Invoices, [spacer], Settings (gear icon), "Developed by Asfar", Sign Out
- **Architecture**: Clean Architecture + BLoC, same patterns as transport/machinery features. GetIt DI with lazy singletons for services/repos, factories for BLoCs.
- **New packages**: `image` (pure Dart image compression), `file_picker` or `image_picker` (for logo/signature upload UI)

---

## Phase 1: Company Profile & Settings Page

**User stories**: 33, 34, 35, 36, 37, 40

### What to build

A complete vertical slice for managing the VRS company profile. The user navigates to a new Settings page (accessible via a gear icon at the bottom of the sidebar) and can view/edit company details, bank information, and upload a logo and signature image. Data persists in a `company_profile` Firestore collection (single document). Uploaded images are compressed client-side before being stored as base64 in Firestore.

This phase is first because the company profile data is a dependency for the invoice PDF generator in Phase 6 — but having it built early also lets users set up their company info before creating any invoices.

### Acceptance criteria

- [ ] `CompanyProfile` entity exists with fields: companyName, gstin, phone1, phone2, email, address, tagline, bankName, bankBranch, accountNo, ifscCode, logoBase64, signatureBase64
- [ ] `CompanyProfileModel` handles Firestore serialization (fromFirestore/toFirestore/fromEntity)
- [ ] Datasource reads/writes a single document in the `company_profile` collection
- [ ] Repository returns `Either<Failure, T>` for all operations
- [ ] `CompanyProfileBLoC` supports Load and Update events
- [ ] Settings page has three form sections: Company Info, Bank Details, Images (logo + signature upload with preview)
- [ ] Image upload compresses to max 300x300px, 80% JPEG quality, stores as base64
- [ ] Settings nav item appears at bottom of sidebar with gear icon, visually separated from main nav
- [ ] Route `/settings` is registered in GoRouter within the ShellRoute
- [ ] All components registered in DI container
- [ ] Firestore constants added for `company_profile` collection and field names
- [ ] If no company profile document exists, Settings page shows empty fields (no crash)

---

## Phase 2: Client Management

**User stories**: 5, 6, 7

### What to build

The data layer and BLoC for managing reusable client profiles. Clients are stored in a `clients` Firestore collection with company name, GSTIN, and address. No dedicated UI pages — the client list and "add new client" dialog will be surfaced through the invoice form in Phase 3. This phase builds the foundation so the invoice form can consume it.

### Acceptance criteria

- [ ] `Client` entity with fields: id, companyName, gstin, address
- [ ] `ClientModel` with fromFirestore/toFirestore/fromEntity
- [ ] Datasource with getClients (ordered by companyName) and createClient methods
- [ ] Repository with `Either<Failure, T>` returns
- [ ] Use cases: `GetClientsUseCase`, `CreateClientUseCase`
- [ ] `ClientBLoC` with Load and Create events/states
- [ ] All components registered in DI container
- [ ] Firestore constants added for `clients` collection and field names

---

## Phase 3: Invoice Data Layer + Create & List

**User stories**: 1, 2, 3, 4, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 26, 39

### What to build

The core invoice feature end-to-end: entity with nested sections and line items, Firestore persistence, invoice number auto-generation, the create form with dynamic sections/line items, and a list page. The invoice form includes the client dropdown (consuming the Client BLoC from Phase 2) with an inline "add new client" dialog. Auto-calculations at this stage cover line item totals (QTY x Rate) and total value (sum of all line items). Tax and recoveries are added in Phase 4.

The form supports multiple sections (first defaults to "Construction of Earth Works"), each with its own line items. Line item serial numbers are continuous across sections.

### Acceptance criteria

- [ ] `InvoiceLineItem` entity with: sacCode, description, unit, qty, rate, totalAmount (auto: qty x rate). Has toMap/fromMap.
- [ ] `InvoiceSection` entity with: header (String), lineItems (List). Has toMap/fromMap.
- [ ] `InvoiceRecord` entity with: id, invoiceNumber, invoiceDate, client (inline Client data), sections, totalValue (auto-calculated sum), tax fields (cgstPercent/sgstPercent/igstPercent and amounts — defaulted to 0 for now), recovery fields (tdsPercent/retentionPercent and amounts — defaulted to 0 for now), subTotal, totalInvoiceValue, amountInWords, createdAt, updatedAt, createdBy
- [ ] `InvoiceRecord.create()` factory computes totalValue from all line items across sections
- [ ] `InvoiceRecordModel` with fromFirestore/toFirestore/fromEntity handling nested sections/lineItems arrays
- [ ] Datasource with CRUD methods + watchInvoices stream + searchInvoices
- [ ] Repository with `Either<Failure, T>` returns
- [ ] Use cases: GetInvoices, GetInvoiceById, CreateInvoice, UpdateInvoice, DeleteInvoice, SearchInvoices
- [ ] `InvoiceBLoC` with Load, Create, Update, Delete, Search, ClearSearch events and real-time stream subscription
- [ ] Invoice number auto-generation: reads/increments `app_config/invoice_counter`, formats as `VRS-{MMM}-{YYYY}-{NNN}`
- [ ] Invoice form page with: date picker, client dropdown (from ClientBLoC) with "Add New Client" option, invoice number field (pre-filled, editable), dynamic sections with editable headers, dynamic line items per section with add/remove, unit dropdown (Cum, Cum-Km, Sqm, Rmt, Nos, Hrs + custom)
- [ ] First section defaults to "Construction of Earth Works"
- [ ] Cannot remove last section; remove section shows confirmation
- [ ] Line item serial numbers continuous across sections
- [ ] Invoice list page showing: invoice number, date, client name, total invoice value
- [ ] List sorted by invoiceDate descending
- [ ] "Invoices" nav item in sidebar between Reports and Settings with receipt icon
- [ ] Routes `/invoices` and `/invoices/create` registered in GoRouter
- [ ] All components registered in DI container
- [ ] Firestore constants added for `invoices` collection and all field names

---

## Phase 4: Tax, Recoveries & Amount in Words

**User stories**: 18, 19, 20, 21, 22, 23, 24, 25

### What to build

Extend the invoice form and entity with the full tax and recovery calculation chain. Add a tax mode toggle (intra-state CGST+SGST vs inter-state IGST), editable percentage fields with auto-calculated amounts, recoveries section (TDS + retention money), and the total invoice value. Build the number-to-Indian-words converter utility and wire it to display the amount in words on the form.

### Acceptance criteria

- [ ] Tax mode toggle on form: "Intra-state (CGST + SGST)" vs "Inter-state (IGST)"
- [ ] Intra-state mode: CGST % (default 9) and SGST % (default 9) editable, IGST locked to 0
- [ ] Inter-state mode: IGST % (default 18) editable, CGST and SGST locked to 0
- [ ] Tax amounts auto-calculated: `totalValue x percent / 100`
- [ ] Sub Total auto-calculated: `totalValue + cgstAmount + sgstAmount + igstAmount`
- [ ] TDS % (default 1) and Retention Money % (default 5) editable in recoveries section
- [ ] Recovery amounts auto-calculated on Sub Total
- [ ] Total Invoice Value auto-calculated: `subTotal - tdsAmount - retentionAmount`
- [ ] `InvoiceRecord.create()` factory updated with full calculation chain
- [ ] Number-to-Indian-words utility created in `core/utils/number_to_words.dart`
- [ ] Handles: zero, large numbers up to crores, decimal paise, "Only" suffix
- [ ] Uses Indian numbering: ones, tens, hundreds, thousands, lakhs, crores
- [ ] Amount in words displayed on form (read-only, auto-updated)
- [ ] All calculations reactive — update on any field change

---

## Phase 5: Invoice Detail, Edit, Delete & Search

**User stories**: 27, 28, 31, 32

### What to build

Complete the CRUD cycle with a detail page, edit flow, delete capability, and search functionality. The detail page shows all invoice information in a read-only layout (similar to transport/machinery detail pages) with toolbar buttons for PDF, Edit, and Delete. Edit loads the existing invoice into the form. Search filters the list by invoice number, client name, or date range.

### Acceptance criteria

- [ ] Invoice detail page displays: invoice number, date, client info (name, GSTIN, address), all sections with line items, tax breakdown, recoveries, total invoice value, amount in words
- [ ] Detail page toolbar has: Back, PDF (disabled until Phase 6), Edit, Delete buttons
- [ ] Edit route `/invoices/edit/:id` lazy-loads invoice via `GetInvoiceByIdUseCase` and opens form pre-filled
- [ ] Detail route `/invoices/detail/:id` registered in GoRouter
- [ ] Editing an invoice preserves the original invoice number (does not re-generate)
- [ ] Delete shows confirmation dialog, removes from Firestore, navigates back to list
- [ ] Search on list page: text field filters by invoice number and client name (client-side)
- [ ] Date range filter on list page (optional — if existing date range patterns exist in reports)
- [ ] List page row/card navigates to detail page on tap
- [ ] List page has context menu or action buttons for quick view/edit/delete

---

## Phase 6: Invoice PDF Export

**User stories**: 29, 30, 38

### What to build

The invoice PDF generator that produces a formatted PDF matching the VRS Enterprises paper invoice layout. Loads company profile data for the header, bank details, logo, and signature. The PDF button on the detail page triggers generation and opens the system print/save dialog.

### Acceptance criteria

- [ ] `InvoicePdfGenerator` static class with `generateAndPrint(InvoiceRecord invoice, CompanyProfile? profile)` method
- [ ] PDF layout matches paper invoice structure:
  - [ ] Company header: logo (if available), company name, GSTIN, phone numbers, email, address, tagline
  - [ ] Invoice number and date (right-aligned)
  - [ ] "Billed To" box with client company name, GSTIN, address
  - [ ] Line items table grouped by section headers, with columns: SL.NO, SAC Code, Description, Unit, QTY, Rate, Total Amount
  - [ ] Total Value row
  - [ ] Tax breakdown: CGST @ X% = amount, SGST @ X% = amount (or IGST @ X% = amount)
  - [ ] Sub Total row
  - [ ] Recoveries section: TDS @ X% = amount, Retention Money @ X% = amount
  - [ ] Total Invoice Value row
  - [ ] Amount in words line
  - [ ] Bank details section: Name, Account No, Bank, Branch, IFSC
  - [ ] Signature area: "For M/S {companyName}" with signature image (if uploaded) or blank space
- [ ] Uses Noto Sans font for rupee symbol support
- [ ] White background, black bordered tables, formal invoice styling
- [ ] PDF filename includes invoice number and date
- [ ] If CompanyProfile is null/empty, PDF generates with placeholder text or omits header (no crash)
- [ ] PDF button on detail page (from Phase 5) is wired to call the generator
- [ ] `Printing.layoutPdf()` opens system print/save dialog
