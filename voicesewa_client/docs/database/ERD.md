Below are **clear ER diagrams** for your **local database layer**, based exactly on your current architecture.
I’ll give you **two levels**:

1. **High-level ER diagram (recommended for docs)**
2. **Detailed table-level ER diagram**

Both are **conceptual ERDs** (SQLite doesn’t enforce all FK constraints, but the relationships exist logically).

---

# 📊 Entity Relationship Diagrams (ERD)

---

## 1️⃣ High-Level ER Diagram (Conceptual)

This shows how **major entities relate** without field-level noise.

```
┌──────────────────┐
│   User Login     │
│------------------│
│ username (PK)    │
│ last_login_at    │
│ is_logged_in     │
└─────────┬────────┘
          │ 1
          │
          │
┌─────────▼────────┐
│ Client Profile   │
│------------------│
│ client_id (PK)   │
│ name             │
│ phone            │
└─────────┬────────┘
          │ 1
          │
          │ N
┌─────────▼────────┐
│ Service Request  │
│------------------│
│ service_request_id (PK)
│ client_id (FK)
│ status
│ scheduled_at
└─────────┬────────┘
          │ 1
          │
          │ N
┌─────────▼────────┐
│ Client Pending   │
│ Sync             │
│------------------│
│ id (PK)          │
│ entityType       │
│ entityId         │
│ action           │
│ syncStatus       │
└──────────────────┘
```

### Relationship Summary

* **UserLogin → ClientProfile**: 1-to-1
* **ClientProfile → ServiceRequest**: 1-to-many
* **Any entity → ClientPendingSync**: 1-to-many (polymorphic)

---

## 2️⃣ Detailed ER Diagram (Table-Level)

This diagram includes **important columns** and **sync relationships**.

```
┌──────────────────────────┐
│        user_login        │
├──────────────────────────┤
│ username (PK)            │
│ password_hash            │
│ last_login_at            │
│ is_logged_in             │
└───────────┬──────────────┘
            │ 1
            │
            ▼
┌──────────────────────────┐
│     client_profile       │
├──────────────────────────┤
│ client_id (PK)           │
│ name                     │
│ phone                    │
│ language                 │
│ created_at               │
│ updated_at               │
└───────────┬──────────────┘
            │ 1
            │
            │ N
            ▼
┌──────────────────────────┐
│   service_requests       │
├──────────────────────────┤
│ service_request_id (PK)  │
│ client_id (FK)           │
│ worker_id                │
│ category                 │
│ title                    │
│ description              │
│ location                 │
│ scheduled_at             │
│ status                   │
│ created_at               │
│ updated_at               │
└───────────┬──────────────┘
            │
            │ creates
            │
            ▼
┌──────────────────────────┐
│  client_pending_sync     │
├──────────────────────────┤
│ id (PK)                  │
│ entityType               │
│ entityId                 │
│ action                   │
│ payload (JSON)           │
│ queuedAt                 │
│ retryCount               │
│ syncStatus               │
│ lastError                │
└──────────────────────────┘
```

---

## 3️⃣ Polymorphic Sync Relationship (Important)

`client_pending_sync` is **polymorphic**:

```
client_pending_sync.entityType
    ├── "service_requests"
    ├── "client_profile"
    └── (future entities)
```

This means:

* One sync table handles **many entities**
* No foreign key constraint
* Resolution happens at **SyncService level**

---

## 4️⃣ Sync-Centric View (Operational ERD)

This diagram explains **why sync works reliably offline**.

```
┌───────────────┐
│ SQLite Tables │
│---------------│
│ client_profile│
│ service_req   │
└───────┬───────┘
        │
        │ enqueue change
        ▼
┌────────────────────┐
│ client_pending_sync│
│--------------------│
│ pending / failed   │
└─────────┬──────────┘
          │
          │ polled
          ▼
┌────────────────────┐
│   SyncService      │
│--------------------│
│ retry logic        │
│ error handling     │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Firebase Firestore │
└────────────────────┘
```

---

## 5️⃣ Why This ER Design Is Strong

✔ **Offline-first**
✔ **No tight coupling to Firestore**
✔ **Easy to add new entities**
✔ **Safe retries without data loss**
✔ **Single sync queue for all features**

---

## 6️⃣ If You Want Visual ERDs

You can easily convert this into:

* **dbdiagram.io**
* **Draw.io**
* **PlantUML**

### Example (dbdiagram.io syntax)

```dbml
Table client_profile {
  client_id text [pk]
  name text
}

Table service_requests {
  service_request_id text [pk]
  client_id text
}

Table client_pending_sync {
  id text [pk]
  entityType text
  entityId text
}
```

---