Below is **clean, focused internal documentation** for **only the database layer** of your app, based strictly on the structure you shared.
This is written as something you can drop into a `DATABASE.md` or internal wiki.

---

# 📦 Database Architecture Documentation

**VoiceSewa Client – Local Database Layer**

This document describes **all local databases, tables, DAOs, and their responsibilities** across the app.

The app follows an **offline-first SQLite architecture** using `sqflite`, with a **generic sync queue** for Firestore synchronization.

---

## 1️⃣ Database Entry Point

### 📄 `core/database/app_database.dart`

**Responsibility**

* Creates and manages the single SQLite database instance.
* Registers all tables.
* Handles migrations and versioning.

**Used by**

* All DAOs via `database_provider.dart`

**Design rule**

> There is **only one SQLite database** for the entire app.

---

## 2️⃣ Database Provider

### 📄 `core/providers/database_provider.dart`

**Responsibility**

* Exposes the SQLite database as a Riverpod `FutureProvider<Database>`
* Ensures lazy, safe, single initialization

**Usage pattern**

```dart
final db = await ref.read(sqfliteDatabaseProvider.future);
```

All DAOs depend on this provider.

---

## 3️⃣ Tables Overview

All table definitions live in:

```
core/database/tables/
```

Tables are **pure schema definitions** (no logic).

---

### 🧑 Client Profile Table

📄 `client_profile_table.dart`

**Purpose**

* Stores the logged-in client’s profile data locally

**Typical fields**

* `client_id` (PK)
* `name`
* `phone`
* `language`
* `created_at`
* `updated_at`

**Synced?**
✅ Yes (via `client_pending_sync`)

---

### 🛠 Service Requests Table

📄 `service_request_table.dart`

**Purpose**

* Stores all service requests created by the client
* Acts as the **primary business entity**

**Typical fields**

* `service_request_id` (PK)
* `client_id`
* `worker_id`
* `category`
* `title`
* `description`
* `location`
* `scheduled_at`
* `status`
* `created_at`
* `updated_at`

**Synced?**
✅ Yes (offline-first, queued for sync)

---

### 🔐 User Login Table

📄 Defined indirectly via
`features/auth/data/database/db_login.dart`

**Purpose**

* Stores authentication/session information locally

**Typical fields**

* `username` (PK)
* `password_hash`
* `last_login_at`
* `is_logged_in`

**Synced?**
❌ No (local-only session control)

---

### 🔄 Client Pending Sync Table (Core Sync Queue)

📄 `client_pending_sync_table.dart`

**Purpose**

* Acts as a **generic sync queue**
* Stores pending CRUD operations for **all syncable entities**

**Fields**

* `id` (PK)
* `entityType` (e.g. `service_requests`)
* `entityId`
* `action` (`INSERT`, `UPDATE`, `DELETE`)
* `payload` (JSON)
* `queuedAt`
* `retryCount`
* `syncStatus` (`pending`, `success`, `failed`)
* `lastError` (nullable)

**This table is the backbone of offline sync.**

---

## 4️⃣ DAO Layer

All DAOs live in:

```
core/database/daos/
```

DAOs are responsible for:

* CRUD operations
* Mapping models ↔ SQLite
* Enqueuing sync events (when applicable)

---

### 👤 ClientProfileDao

📄 `client_profile_dao.dart`

**Manages**

* `client_profile` table

**Responsibilities**

* Insert/update client profile
* Read profile for logged-in user
* Enqueue sync on changes

**Used by**

* `client_profile_provider`
* Auth & profile UI

---

### 📋 ServiceRequestDao

📄 `service_request_dao.dart`

**Manages**

* `service_requests` table

**Responsibilities**

* Create/update/delete service requests
* Read service requests for UI
* Automatically enqueue sync via `ClientPendingSyncDao`

**Key behavior**

> Every local change creates a pending sync entry.

---

### 🔐 DbLoginDao

📄 `features/auth/data/daos/db_login_dao.dart`

**Manages**

* `user_login` table

**Responsibilities**

* Login/logout
* Session persistence
* Last login timestamp

**Note**

* This DAO **does not participate in sync**

---

### 🔄 ClientPendingSyncDao

📄 `client_pending_sync_dao.dart`

**Manages**

* `client_pending_sync` table

**Responsibilities**

* Enqueue sync jobs
* Fetch pending / failed jobs
* Update retry count & sync status
* Clear successful entries

**Used by**

* `SyncService`
* Debug UI
* Sync status providers

---

## 5️⃣ Sync Service (Database Consumer)

### 📄 `features/sync/data/sync_service.dart`

**Consumes**

* `ClientPendingSyncDao`

**Responsibilities**

* Read pending sync entries
* Push changes to Firestore
* Update sync status per entry
* Retry failures safely

**Important**

> SyncService NEVER touches business tables directly.
> It only works through `client_pending_sync`.

---

## 6️⃣ Data Flow Summary

```
UI
 ↓
Riverpod Provider
 ↓
DAO
 ↓
SQLite Table
 ↓
ClientPendingSync (if syncable)
 ↓
SyncService
 ↓
Firestore
```

---

## 7️⃣ Architectural Principles

* **Offline-first**
* **Single SQLite database**
* **Tables = schema only**
* **DAOs = logic**
* **ClientPendingSync = universal sync queue**
* **Firestore is never read by UI directly**

---

## 8️⃣ Where to Add New Tables

If you add a new feature with local persistence:

1. Add table schema → `core/database/tables/`
2. Add DAO → `core/database/daos/`
3. Register table in `app_database.dart`
4. (Optional) enqueue sync via `ClientPendingSyncDao`

---

