---
title: VoiceSewa Documentation
---
  
# VoiceSewa — Complete System Documentation

**PS 04: Multilingual Voice-Assisted Job Connection Platform for Blue-Collar Services**

> Connect with a trusted plumber, carpenter, or electrician by speaking in your own language — even on low connectivity.

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Solution Overview](#solution-overview)
3. [System Architecture](#system-architecture)
4. [Component Index](#component-index)
5. [Client App (VoiceSewa)](#client-app-voicesewa)
6. [Worker App (VoiceSewa-Worker)](#worker-app-voicesewa-worker)
7. [Auto Call Translation Backend (VoiceSewa-AutoCallTranslate)](#auto-call-translation-backend)
8. [Firebase Functions & N8N Automation (VoiceSewa-FirebaseFunctions)](#firebase-functions--n8n-automation)
9. [Shared Firebase Schema](#shared-firebase-schema)
10. [Multilingual Support](#multilingual-support)
11. [Offline & Low-Bandwidth Support](#offline--low-bandwidth-support)
12. [Trust & Security Features](#trust--security-features)
13. [PS 04 Bonus Features](#ps-04-bonus-features)
14. [End-to-End Feature Flows](#end-to-end-feature-flows)
15. [Setup & Running](#setup--running)

---

## Problem Statement

Millions of blue-collar workers — carpenters, plumbers, electricians, painters — rely entirely on word-of-mouth to find jobs. Individuals who need these services struggle to find trusted, available workers quickly. Existing platforms are:
- **English-only and text-heavy** — inaccessible to workers comfortable only in Hindi, Marathi, or Gujarati
- **Internet-dependent** — unusable in rural and semi-urban areas with poor connectivity
- **Designed for tech-savvy users** — complex navigation, minimal voice interaction
- **Opaque on trust** — no verified profiles, no OTP-based accountability

Language, digital literacy, and connectivity barriers leave a large population of both workers and clients underserved.

---

## Solution Overview

VoiceSewa is a **dual-app, voice-first, multilingual, offline-capable platform** that connects individuals with skilled blue-collar workers — in their own language. The system is built around four guiding principles:

### 1. Voice First
Every critical action — posting a job, submitting a quotation, getting help — can be done by speaking rather than typing. The Voice Bot assistant guides users through the platform in their native language. In-app calls use real-time speech recognition and translation so a Hindi-speaking client and an English-speaking worker can talk naturally with no shared language.

### 2. Multilingual by Default
The entire UI is available in **English, Hindi, Marathi, and Gujarati** with one-tap language switching. Chat messages are automatically translated into all four languages so workers and clients can read every message in their own language. Speech-to-text, TTS responses, and the AI voice assistant all respect the user's chosen language.

### 3. Trust & Accountability
- **Aadhaar QR verification** for worker identity (decoded via a dedicated FastAPI microservice)
- **OTP-based job start** — the worker must present an OTP to the client before work begins, confirming arrival
- **In-app calls with number masking** — no phone number exchange between strangers
- **Verified badges** on workers with strong track records (5+ reviews, 4.5+ avg rating)
- **Automatic rating recalculation** after every completed job, via Firebase Cloud Function
  
### 4. Offline & Low-Bandwidth Capable
- Firestore offline persistence (unlimited cache) serves all screens from local cache
- SQLite local database for structured offline data
- Lightweight, minimal-step UI designed for low digital literacy users
- Connectivity detection before network operations, with graceful degradation

### What We Built

| Component | Description |
|---|---|
| **Client Flutter App** | Post service requests via voice/text, browse workers, compare quotations, book, chat, call |
| **Worker Flutter App** | Receive job notifications, submit quotations, chat, start/complete jobs, track earnings |
| **Auto Call Translation Backend** | Node.js + WebSocket service on Cloud Run — real-time STT → Translate → TTS pipeline |
| **Node.js REST API** | Express.js API server for CRUD operations on jobs, quotations, users |
| **AI Demand Forecast Analyzer** | Python Flask + scikit-learn model predicting worker demand by district and season |
| **Firebase Cloud Functions** | 11 event-driven functions for notifications, data management, rating aggregation |
| **N8N Workflow Automation** | 7 workflows: AI chat assistant (Gemini), call notifications, chat translation, Firestore CRUD, IVR |
| **Aadhaar QR Service** | FastAPI microservice for decoding Aadhaar QR codes to verify worker identity |

---

## System Architecture

```
┌───────────────────────────────────────────────────────────────────────┐
│                          CLIENT-SIDE APPS                             │
│                                                                       │
│   ┌─────────────────────────────┐   ┌─────────────────────────────┐   │
│   │     Flutter Client App      │   │     Flutter Worker App      │   │
│   │  (Riverpod + Firebase SDK)  │   │  (Riverpod + Firebase SDK)  │   │
│   └─────────────┬───────────────┘   └───────────────┬─────────────┘   │
└─────────────────┼───────────────────────────────────┼─────────────────┘
                  │                                   │
                  └────────────────┬──────────────────┘
                                   │
        ┌──────────────────────────▼──────────────────────────┐
        │                  FIREBASE BACKEND                   │
        │   Firebase Auth │ Firestore │ Firebase Messaging    │
        └─────────────┬────────────────────────────┬──────────┘
                      │                            │
          ┌───────────▼─────────┐    ┌─────────────▼───────────────┐
          │ Firebase Cloud      │    │        N8N Workflows        │
          │ Functions (Node 20) │    │    (Hosted on n8n.cloud)    │
          │ 11 Firestore        │    │  AI Chat · Translation ·    │
          │ event triggers      │    │  IVR · FCM · Firestore CRUD │
          └─────────────────────┘    └─────────────────────────────┘
                      │
       ┌──────────────┼──────────────────────────────┐
       │              │                              │
┌──────▼──────┐ ┌─────▼───────────────┐ ┌────────────▼────────────────┐
│ Node.js API │ │ Auto Call Translate │ │ Aadhaar QR Decode Service   │
│  (Railway)  │ │  Backend            │ │  (Python FastAPI, Render)   │
│  Express.js │ │  (Node.js + WS,     │ │  Decodes Aadhaar QR codes   │
│  REST API   │ │   GCP Cloud Run)    │ │  for worker verification    │
│  + ML Flask │ │  Google STT/TTS/    │ └─────────────────────────────┘
│  Forecast   │ │  Translate APIs     │
└─────────────┘ └─────────────────────┘
```

---

## Component Index

| Branch | Stack | Deployment | Purpose |
|---|---|---|---|
| `client/main` | Flutter + Riverpod | Android / iOS | Client app |
| `worker/main` | Flutter + Riverpod | Android / iOS | Worker app |
| `backend/features/auto-translate-call` | Node.js + WebSocket | GCP Cloud Run (asia-south1) | Real-time voice call translation |
| `backend/node` | Node.js Express + Python Flask | Railway (API) + Docker (ML) | REST API + AI demand forecast |
| `firebase/functions` | Node.js Firebase Functions + N8N | Firebase + n8n.cloud + Render | Event functions + automation |

---

## Client App (VoiceSewa)

### Overview

The client app is the interface for individuals seeking blue-collar services. It supports voice-first job posting, worker discovery by location and skill, quotation comparison, in-app calling with live translation, and multilingual AI assistant support.

**SDK:** Flutter 3.9.2+ / Dart 3.9.2+
**State Management:** Riverpod 3.0.3
**Architecture:** Clean Architecture, feature-based module structure

### Feature Modules

#### Authentication & Profile
- Firebase Auth (email/password) with session restoration via `AppGate`
- Post-registration profile setup: name, phone, address with GPS
- Multiple saved addresses with geocoding
- FCM token auto-saved on login, cleared on logout

#### Home
- Quick action shortcuts for all 10 service types
- Quick book section for frequently used services
- Recent service requests summary
- 5-tab bottom navigation: Home, Search, VoiceBot, History, Settings

#### Job Posting
- Voice or text job creation with service type selection
- Address selection from saved or new (GPS-assisted)
- Job status lifecycle: `requested → quoted → scheduled → in_progress → completed`
- Job details: status badge, assigned worker, bill breakdown, client and worker feedback
- Book Again: one-tap re-booking from any completed job

#### Worker Search & Discovery
- **Geolocation-based** worker listing using Haversine distance formula
- Filter by: profession, distance (2–5 km), rating
- Sort by: distance, rating, price
- Worker cards: name, profession, rating, distance, verified badge
- Verified badge: 5+ reviews with 4.5+ average rating
- Worker detail bottom sheet: bio, skills, experience, reviews, contact options

#### Quotation Management
- View all worker quotations for each job
- Per-quotation: estimated cost, time, description, price breakdown, notes
- Accept or reject quotations
- Quotation statuses: `submitted → accepted / rejected / withdrawn`
- `viewed_by_client` flag tracked per quotation

#### In-App Chat
- Real-time messaging with workers inside a quotation context
- Stored in `jobs/{jobId}/quotations/{quotId}/messages`
- Auto-translated to all 4 languages via N8N workflow (stored in `translated` map)
- Sender identification (client vs worker)

#### In-App Voice Calls (with Live Translation)
- Outgoing calls to workers from job or quotation screens
- Incoming call screen with accept/reject
- Active call screen with real-time transcript overlay
- Call state machine: `idle → outgoing / incoming → connecting → active → ended`
- WebSocket-based audio streaming to Cloud Run backend
- **Number masking**: no phone number exchange
- Real-time STT → Translate → TTS so calls work across language barriers
- Firestore `calls/{sessionId}` used for signaling

#### Voice Bot 
- Floating assistant accessible from the bottom nav bar
- Record voice query, send as base64 to N8N `/webhook/chat`
- N8N invokes Google Gemini (LLM) + TTS; response played as audio
- Chat UI with voice bubbles and text transcript
- Non-blocking: conversation continues while audio plays

#### Request History
- All past requests filterable by: All, Requested, Quoted, Scheduled, In Progress, Completed, Cancelled
- Job cards with status badge, service icon, date, worker info

#### Settings
- Language selection (4 languages, persisted to `shared_preferences`)
- Notification preferences
- Address management
- Support / FAQ
- Account settings (password change, account deletion)
- Secure logout with FCM token cleanup

### Key Packages

  | Package | Version | Purpose |
  |---|---|---|
  | flutter_riverpod | ^3.0.3 | State management |
  | firebase_core | ^4.2.1 | Firebase init |
  | firebase_auth | ^6.1.3 | Auth |
  | cloud_firestore | ^6.1.0 | Real-time DB |
  | firebase_messaging | ^16.1.1 | Push notifications |
  | speech_to_text | ^7.3.0 | On-device STT |
  | record | ^6.2.0 | Audio recording |
  | just_audio | ^0.10.5 | Audio playback |
  | audioplayers | ^6.5.1 | Additional playback |
  | web_socket_channel | ^3.0.0 | WebSocket calls |
  | geolocator | ^14.0.2 | GPS |
  | geocoding | ^4.0.0 | Address geocoding |
  | flutter_map | ^8.2.2 | OpenStreetMap display |
  | connectivity_plus | ^7.0.0 | Network detection |
  | sqflite | ^2.4.2 | SQLite local DB |
  | shared_preferences | ^2.5.3 | Local storage |
  | freezed_annotation | ^2.4.4 | Immutable models |
  | http | ^1.6.0 | HTTP requests |

### Routing

```
AppGate (auth guard)
  ├── LoginScreen
  ├── ProfileFormScreen (post-registration)
  └── HomePage (bottom nav)
        ├── Tab 0: Home
        ├── Tab 1: WorkersPage (Search)
        ├── Tab 2: VoiceBotPage
        ├── Tab 3: MyRequestsPage (History)
        └── Tab 4: SettingsPage
              └── SupportPage
```

Call screens are pushed imperatively on the root Navigator via `_CallListener` in `app.dart` as full-screen overlays. FCM tap routing is handled by `NotificationRouter` which maps notification `type` → screen.

### Services Enum (10 categories)

```
Electrician · Plumber · Carpenter · Painter
AC/Appliance Technician · House Cleaner
Driver on Demand · Cook · Mechanic · Handyman/Masonry
```

Each carries: icon, color, display label (localized).

---

## Worker App (VoiceSewa-Worker)

### Overview

The worker app is the interface for blue-collar workers to discover nearby jobs matching their skills, submit competitive quotations, communicate with clients, and manage their earnings.

**SDK:** Flutter 3.9.2+ / Dart 3.9.2+
**State Management:** Riverpod 3.0.3
**Architecture:** Clean Architecture, feature-based module structure

### Feature Modules

#### Authentication & Verification
- Firebase Auth (email/password)
- Post-registration worker profile form: name, phone, bio, location, skills
- **Aadhaar QR code scanning** for identity verification (`mobile_scanner` package)
- FCM token management on login/logout

#### Job Discovery & Management

**Incoming Jobs (Real-time Stream)**
- Real-time Firestore stream of jobs filtered by:
  - Worker skill match (any of worker's declared skills matches `service_type`)
  - Distance ≤ 5 km (Haversine formula on client side)
  - Excluding jobs the worker already declined
  - Status override: shows as "quoted" for jobs where worker already applied
- Each job card shows: service type, client location, description, distance

**Job Lifecycle (Worker Side)**

```
Incoming job visible  →  Submit quotation  →  Client accepts  →  Schedule  →  OTP Verify  →  Mark Complete  →  Bill + Feedback
```

- **Submit Quotation**: cost estimate, time estimate, description, price breakdown, notes, availability
- **Update Quotation**: allowed before the client views it (`viewed_by_client` flag)
- **Withdraw Quotation**: marks as withdrawn with reason
- **Decline Job**: removes from worker's incoming stream
- **OTP Verification**: client shares OTP when worker arrives; worker enters it to start job
- **Bill Generation**: itemized bill (name, quantity, unit price) sent to client on completion
- **Worker Feedback**: star rating + comment after job completion

**Three-Tab Job View**: Incoming · Ongoing · Completed · Declined / Withdrawn

#### In-App Chat
- Real-time messaging within each quotation
- Stored in Firestore subcollection
- Messages have auto-translated text for all 4 languages
- Sender badges (worker/client)

#### In-App Voice 
- Same WebSocket backend as client app
- Outgoing calls: worker calls client from job detail screen
- Incoming calls: detected via Firestore listener on `calls/{sessionId}` where `receiverUid == workerUid`
- Real-time transcripts with language labels
- Number masking throughout

#### Earnings 
- Total earnings display
- Monthly income breakdown
- Transaction history per job
- Earnings chart (SyncFusion line chart + fl_chart)
- Summary cards: Total Earned, Available for Withdrawal, Jobs Completed

#### Profile Management
- Edit name, phone, bio, location, skills
- Profile photo upload (Firebase Storage)
- Aadhaar verification status
- Bank details page (payment payout)
- Work history view
- Average rating display
- Verified badge indicator

#### Voice Bot Assistant
- Same architecture as client — record, send to N8N, receive audio response
- Configured with `type: 'worker'` context in webhook payload

#### Settings
- Language switching (4 languages, persisted)
- Push notification preferences
- Help & Support (FAQ, email, phone)
- Logout with full cleanup

### Key Packages (Worker-Exclusive)

| Package | Version | Purpose |
|---|---|---|
| mobile_scanner | ^7.2.0 | Aadhaar QR scanning |
| firebase_storage | ^13.0.6 | Profile photo upload |
| syncfusion_flutter_charts | ^31.2.12 | Earnings charts |
| fl_chart | ^1.1.1 | Alternative charts |
| dart_geohash | ^2.1.0 | Geohash computation for location indexing |
| image_picker | ^1.2.1 | Camera / gallery |
| url_launcher | ^6.3.2 | Open maps / dial |

### Routing

```
AppGate (auth guard)
  ├── LoginScreen / SignupScreen
  ├── ProfileCheckHandler (routes to form if profile incomplete)
  └── RootScaffold (bottom nav)
        ├── Tab 0: HomePage (insights, ratings)
        ├── Tab 1: MyJobsPage (Incoming / Ongoing / Completed)
        ├── Tab 2: VoiceBotPage
        ├── Tab 3: EarningsPage
        └── Tab 4: ProfilePage
              ├── WorkerProfileFormPage
              ├── SettingsPage
              ├── BankDetailsPage
              ├── WorkHistoryPage
              └── SupportAndHelpPage
```

### Worker Job State Machine

```
Worker's perspective:
  Incoming job stream
        ↓
  Apply (submit quotation)
        ↓
  Client accepts quotation        ← auto-rejects all other submitted quotations
        ↓
  Job scheduled (worker notified)
        ↓
  OTP verification (worker arrival confirmed)
        ↓
  Job in progress
        ↓
  Job completed + bill submitted
        ↓
  Worker leaves feedback
```

---

## Auto Call Translation Backend

**Branch:** `backend/features/auto-translate-call`
**Deployment:** GCP Cloud Run, region asia-south1 (Mumbai)

### What It Does
  
Real-time multilingual voice call translation. When a Hindi-speaking client calls an English-speaking worker (or any cross-language pair), this service:

1. Captures audio from each party via WebSocket
2. Runs **Google Speech-to-Text** in the speaker's language → text transcript
3. Runs **Google Translate** → translated text in the partner's language
4. Runs **Google Text-to-Speech** → synthesized audio in the partner's language
5. Streams the translated audio back to the partner in real time
6. Emits live transcript events to both UIs

Both parties hear natural speech in their own language while reading a live transcript on screen.

### Technology Stack

| Component | Technology |
|---|---|
| Runtime | Node.js 22 on Alpine Linux |
| Web framework | Express.js v4.19.2 |
| WebSocket | ws v8.18.0 |
| Authentication | Firebase Admin SDK v12.3.0 (JWT) |
| STT | Google Cloud Speech-to-Text v6.7.0 |
| Translation | Google Cloud Translate v8.5.0 |
| TTS | Google Cloud Text-to-Speech v5.3.0 |
| Signaling DB | Firestore |
| Deployment | GCP Cloud Run + Cloud Build CI/CD |

### REST API

| Endpoint | Auth | Purpose |
|---|---|---|
| `GET /health` | None | Liveness probe; returns `activeSessions` count |
| `POST /session` | Firebase Bearer | Create call session; returns `sessionId` + `wsUrl` |
| `GET /session/:id` | Firebase Bearer | Check session status and connected user count |
| `DELETE /session/:id` | Firebase Bearer | Manually end session |

### WebSocket API

**Connection URL:**
```
wss://<host>/ws?token=<firebase-id-token>&sessionId=<id>&sourceLang=hi-IN&targetLang=en&voiceLang=en-IN
```

**Client → Server:**
- Binary frames: raw PCM16 mono 16 kHz audio chunks (100 ms, ~3200 bytes each)
- `{ "type": "ping" }` — keep-alive (server responds with `{ "type": "pong" }`)

**Server → Client:**
- `{ "type": "connected", userIndex, sessionId, sourceLang, targetLang, voiceLang }` — on connect
- `{ "type": "call_started", sessionId }` — when both parties are connected
- `{ "type": "transcript", text, isFinal, lang }` — live STT events (interim + final)
- Binary frames: PCM16 audio of partner's translated speech
- `{ "type": "partner_left", sessionId }` — partner disconnected
- `{ "type": "error", code, message }` — error events

### Audio Pipeline (Per User)

```
Microphone (PCM16 mono 16kHz)
      ↓
Google STT  (streamingRecognize, 'latest_long' model, interim results ON)
      ↓
Transcript events → client UI (live transcription)
      ↓
[On FINAL transcript only]
      ↓
Google Translate (source base-lang → target base-lang)
      ↓
Google TTS (Neural2 voice, fallback to Standard for regional languages)
      ↓
PCM16 audio → partner's speaker
```

### Session Lifecycle & TTL Strategy

| TTL | Duration | Trigger | Handles |
|---|---|---|---|
| WAITING_TTL | 90 seconds | Session created, no WS yet | Missed FCM, declined calls |
| RINGING_TTL | 60 seconds | First user connects | Partner never arriving; mid-call reconnect window |
| CALL_TTL | 2 hours | Session created | Absolute max call duration |

Google STT streams have a 305-second hard limit; the service proactively restarts at 290 seconds to avoid dropout.

### Language Support
- **STT input**: any BCP-47 code supported by Google (hi-IN, en-US, en-IN, mr-IN, gu-IN, ...)
- **Translation**: any pair of 130+ languages via Google Translate
- **TTS Neural2 voices**: en, hi, fr, de, es, it, ja, ko, pt, cmn, ar, nl, pl, sv, tr, vi
- **TTS Standard fallback**: ml-IN, pa-IN, gu-IN, bn-IN and others

### Deployment (Cloud Run)

| Setting | Value |
|---|---|
| Region | asia-south1 (Mumbai) |
| Min instances | 1 (in-memory sessions require same instance) |
| Max instances | 10 |
| Concurrency | 80 per instance |
| Memory | 512 MB |
| Timeout | 3600 s |
| Session affinity | Yes (GCILB cookie) |
| CI/CD | Cloud Build auto-deploy on push |

### Firebase Cloud Function (in this repo)

`sendCallNotification` — triggers on `calls/{sessionId}` creation with `status: "ringing"`, sends high-priority FCM to the receiver so the incoming call screen appears immediately.

---

## AI Forecast Backend

**Branch:** `backend/node`
**ML Component:** Python Flask + scikit-learn (Docker, deployed separately)

### AI Demand Forecast Analyzer

**Location:** `ml/` directory
**Framework:** Python Flask (port 5000), Gunicorn in production
**Model:** Scikit-learn regression model (`voicesewa_model.pkl`, 5.9 MB)

#### What It Does

Predicts worker demand by job type and district based on seasonal patterns. Helps surface high-demand services in specific geographic areas so workers can focus their availability and platform can guide supply-demand matching.

#### Forecast Output

```json
{
  "currentForecast": {
    "season": "Summer",
    "top5Jobs": ["Electrician", "Plumber", "AC Technician", "Painter", "Mechanic"],
    "forecast": {
      "Andheri":  { "Electrician": 18.5, "Plumber": 14.2, ... },
      "Panvel":   { ... },
      "Thane":    { ... },
      "Virar":    { ... }
    }
  }
}
```

#### Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/` | Health check |
| GET | `/current-forecast` | Current month's district × job demand |
| GET | `/next-forecast` | Next month's projected demand |

#### Model Details
- **Training data:** 160 records across 4 districts × 10 job types × 4 seasons
- **Features:** `jobsCompleted`, `experienceYears`, `isMultiTalented`
- **Target:** `seasonalDemandScore`
- **Seasons:** Summer (Mar–May), Monsoon (Jun–Sep), Festival (Oct–Nov), Winter (Dec–Feb)
- **Districts:** Andheri, Panvel, Thane, Virar
- **Deployment:** Dockerized with Gunicorn WSGI server

---

## Firebase Functions & N8N Automation

**Branch:** `firebase/functions`
This repository contains three layers of backend automation:
1. **11 Firebase Cloud Functions** — event-driven Firestore triggers
2. **7 N8N workflows** — multi-service orchestration
3. **Aadhaar QR Decode microservice** — Python FastAPI on Render

### Firebase Cloud Functions (Node.js 20)

All functions use Firebase Functions SDK v2 (v7.0.6) with Firestore event triggers.

#### Notification Functions — Workers (4)

| Function | Trigger | Purpose |
|---|---|---|
| `notifyNearbyWorkers` | `jobs/{jobId}` created | Geohash-based nearby worker matching; sends multicast FCM to all workers with matching skills within ~1.2 km cells |
| `notifyWorkerOnJobStatus` | `jobs/{jobId}` updated | Notifies assigned worker on status → `scheduled / rescheduled / inProgress / completed / cancelled` |
| `notifyWorkerOnQuotationStatus` | `jobs/{jobId}/quotations/{quotId}` updated | Notifies worker when quotation is `accepted` or `rejected` (manual or auto) |
| `notifyWorkerOnNewMessage` | message created (`is_worker !== true`) | Notifies worker of new client message; includes 60-char preview |

#### Notification Functions — Clients (4)

| Function | Trigger | Purpose |
|---|---|---|
| `notifyClientOnNewQuotation` | quotation created | Notifies client: "{workerName} submitted a quotation for your {serviceType} job" |
| `notifyClientOnQuotationWithdrawn` | quotation status → `withdrawn` | Notifies client that a worker withdrew |
| `notifyClientOnNewMessage` | message created (`is_worker === true`) | Notifies client; includes `worker_name` in data payload for direct ChatScreen routing |
| `notifyClientOnJobStatus` | job status → `inProgress / completed` | "Work Has Started" / "Job Completed, please review the bill" |

#### Data Management Functions (3)

| Function | Trigger | Purpose |
|---|---|---|
| `onQuotationAccepted` | quotation written with status → `accepted` | Batch: moves job ref from worker's `applied` → `confirmed`; auto-rejects all other `submitted` quotations for the same job |
| `onQuotationAutoRejected` | quotation status → `rejected` | Moves job ref from worker's `applied` → `declined` |
| `recalculateWorkerAvgRating` | job written with `client_feedback.rating` changed | Fetches all worker's completed jobs, recalculates mean rating (1 decimal place), updates `worker.avg_rating` |

**Geo-matching strategy:** `notifyNearbyWorkers` generates the job's geohash at precision 5 + all 8 neighbors (9 cells covering ~1.2 km radius), queries workers by geohash, then filters by skill match and FCM token availability.

**FCM token cleanup:** Invalid tokens returned by Firebase are automatically removed from worker/client documents.

### N8N Workflows

Hosted on n8n.cloud

#### 1. VoiceSewa — Main (AI Chat)

**Webhook:** `POST /webhook/chat`
**Payload:** `{ uid, msg, lang, type, system_prompt, profile }`
**Response:** `{ response: string, base64Audio: string }`

Pipeline:
1. Normalize webhook params
2. Validate user role and context
3. Build system prompt with user profile
4. **Google Gemini** (`models/gemini-3-flash-preview`) with sliding window memory (10 messages, keyed `type-uid-v19`)
5. Convert response to audio via TTS endpoint
6. Return JSON with text + base64 audio

Used by both the client Voice Bot and worker Voice Bot (differentiated by `type: 'client'` or `type: 'worker'`).

#### 2. Call_Notification

**Webhook:** `POST /webhook/call-notification`
**Payload:** `{ receiverId, jobId, callerName, type, goToCollection }`

Fetches the receiver's `fcm_token` from Firestore (`/{goToCollection}/{receiverId}`), sends FCM push with `{ type: "voice_call", jobId }` at high priority.

#### 3. IVR_Call_Translation

**Webhook:** `POST /webhook/translate-call`
**Payload:** `{ audio_to_translate (binary), translate_to (lang code) }`
**Response:** Raw PCM 16-bit audio

Pipeline:
1. **Groq API** (`whisper-large-v3`) → transcription
2. **Google Translate** → translated text
3. **Sarvam AI** (`bulbul:v3`, speaker: `shubh`) → Indian-language TTS audio
4. Strip 44-byte WAV header → return raw PCM for direct playback

Used as the translation pipeline for voice calls (alternative path for Sarvam-based Indian language TTS).

#### 4. Chat_Translation

**Webhook:** `POST /webhook/translate`
**Payload:** `{ originalMsg, jobId, quotationId, msgId }`

Runs 4 parallel Google Translate calls (EN, HI, MR, GU), merges results, upserts to Firestore:
```
jobs/{jobId}/quotations/{quotationId}/messages/{msgId}
  translated: { en: "...", hi: "...", mr: "...", gu: "..." }
```

#### 5. Firestore (Sub-workflow)

Reusable sub-workflow called by other workflows. Supports 17 CRUD operations:
`GET_JOBS_BY_IDS · GET_JOB_BY_ID · CREATE_JOB · UPDATE_JOB_STATUS · GET_QUOTATIONS · GET_QUOTATION_BY_ID · UPDATE_QUOTATION_STATUS · FINALIZE_JOB_QUOTATION · ADD_QUOTATION_MESSAGE · VERIFY_OTP · ADD_FEEDBACK · UPDATE_QUOTATION · WITHDRAW_QUOTATION · ADD_ADDRESS · CHECK_USER_EXISTS · CREATE_CLIENT_ACCOUNT · CREATE_WORKER_ACCOUNT`

Each action has strict input validation. Provides a clean abstraction over Firestore for other N8N workflows.

#### 6. Hybrid_IVR

**Webhook:** `POST /webhook/ivr_entry`

Voice IVR entry point for accessibility-focused job posting. Routes based on `client` or `worker` query param, fetches Firestore data, returns TWIML XML (`<Say>`, `<Hangup>`) for phone-based interaction. Currently in development — enables job posting and acceptance through number-press menus when internet is unavailable.

### Aadhaar QR Decode Microservice

**Framework:** Python FastAPI (Uvicorn), deployed on Render.com
**Purpose:** Decode Aadhaar QR codes for worker identity verification

#### Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | `{ "status": "ok" }` |
| POST | `/decode-aadhaar` | Decode QR string; returns verified identity info |

**Request:** `{ "qr_data": "<raw QR string>" }`

**Response:**
```json
{
  "success": true,
  "name": "Worker Name",
  "gender": "M",
  "dob": "1990-01-01",
  "address": "Full formatted address",
  "state": "...",
  "district": "...",
  "pincode": "...",
  "uid_last4": "1234",
  "photo_base64": "<base64 image>",
  "is_secure_qr": true
}
```

Only the last 4 digits of the Aadhaar UID are returned — the full UID is masked for privacy. Handles both Secure QR (numeric, 100+ chars) and Old QR formats.

**Dependencies:** `pyaadhaar`, `opencv-python-headless`, `fastapi`, `uvicorn`

---

## Shared Firebase Schema

Both apps share the same Firebase project. All data lives in Firestore.

```
clients/
  {uid}/
    name, email, phone
    addresses[]              ← Array of Address objects
      location (GeoPoint), line1, line2, landmark, city, pincode
    services/
      requested[]            ← Job document IDs
      scheduled[]
      completed[]
      cancelled[]
    fcm_token

workers/
  {uid}/
    name, email, phone, bio, profile_img
    avg_rating               ← Recalculated by Cloud Function after each job
    reviews[]                ← { rating, review }
    skills[]                 ← service type strings
    address/
      location (GeoPoint), city, pincode
      geohash                ← Precision 5, used by notifyNearbyWorkers
    jobs/
      applied[]              ← DocumentReferences
      confirmed[]
      completed[]
      declined[]
    fcm_token
    is_worker_verified       ← Set after Aadhaar verification

jobs/
  {jobId}/
    service_type             ← Services enum name
    description
    address/
      location (GeoPoint), city, pincode, geohash
    client_uid, created_at, status
      requested | quoted | scheduled | inProgress | completed | cancelled | rescheduled
    scheduled_at?, started_at?
    finalized_quotation?     ← DocumentReference to accepted quotation
    finalized_quotation_amount?
    worker_name?, worker_rating?, client_phone?
    otp?                     ← Shown to client, verified by worker on arrival
    bill?/
      items[] { name, quantity, unit_price }
      total_amount, notes, created_at
    worker_feedback?/        ← Worker's review of client
      rating, comment, created_at
    client_feedback?/        ← Client's review of worker (triggers rating recalculation)
      rating, comment, created_at

    quotations/
      {quotationId}/
        worker_uid, worker_name, worker_rating
        estimated_cost, estimated_time, description
        price_breakdown?, notes
        portfolio_photo_ids[]
        availability, status
          submitted | accepted | rejected | withdrawn
        viewed_by_client, viewed_at
        created_at, updated_at
        accepted_at?, rejected_at?, withdrawn_at?
        rejection_reason?, withdrawal_reason?
        auto_rejected?       ← True when rejected because another quotation was accepted

        messages/
          {messageId}/
            sender_uid, sender_name
            originalMsg
            translated/      ← Written by Chat_Translation N8N workflow
              en, hi, mr, gu
            is_worker
            sent_at

calls/
  {sessionId}/
    callerUid, receiverUid
    callerName, receiverName
    callerLang, receiverLang
    status                   ← ringing | active | ended
    createdAt, endedAt?
    durationSeconds?
    receiverFcmToken?        ← Used by Cloud Function for immediate push
```

---

## Multilingual Support

 Both apps support 4 languages with runtime switching persisted across sessions.

| Language | Code | ARB File |
|---|---|---|
| English | `en` | `app_en.arb` |
| Hindi | `hi` | `app_hi.arb` |
| Marathi | `mr` | `app_mr.arb` |
| Gujarati | `gu` | `app_gu.arb` |

**Implementation:**
- Flutter ARB (Application Resource Bundle) with `flutter gen-l10n`
- Strongly-typed `AppLocalizations` class, accessed via `context.loc.keyName` extension
- `LocaleNotifier` (Riverpod `StateNotifier`) manages current locale
- `shared_preferences` persists language choice

**Voice input localization:**
- BCP-47 code mapping: `en → en-IN`, `hi → hi-IN`, `mr → mr-IN`, `gu → gu-IN`
- Passed to `speech_to_text` for correct language recognition model

**Chat translation:**
- Every message automatically translated to all 4 languages by N8N workflow
- Apps display the translation matching user's selected language

**Call translation:**
- Auto Call Translate backend maps app locale to Google STT/TTS language codes
- Neural2 voices for Hindi and English; Standard fallback for Gujarati, Marathi

---

## Offline & Low-Bandwidth Support

| Mechanism | Where | Details |
|---|---|---|
| Firestore offline persistence | Both apps | Unlimited cache; reads from local store first |
| Cache-first data fetch | Both apps | UI renders from cache instantly; server syncs in background |
| Connectivity detection | Both apps | `connectivity_plus` gates network calls |
| Lightweight UI | Both apps | Large touch targets, minimal steps for low-literacy users |
| App-level graceful degradation | Both apps | Falls back silently; no crash on offline |

---

## Trust & Security Features

| Feature | Implementation |
|---|---|
| **Aadhaar QR Verification** | Worker scans Aadhaar QR → FastAPI service decodes → masked identity stored; `is_worker_verified` flag set |
| **OTP job start** | Unique OTP stored in job document, shown to client, entered by worker on arrival to start job |
| **Number masking** | All calls go through WebSocket backend — neither party's phone number is exchanged |
| **Verified badge** | Workers need 5+ reviews with 4.5+ avg rating; recalculated by Cloud Function on each feedback |
| **Firebase Auth** | All users authenticated with Firebase; all backend APIs verify Firebase ID tokens |
| **FCM token lifecycle** | Tokens saved on login, cleared on logout; invalid tokens auto-removed by Cloud Functions |
| **Quotation view tracking** | Workers cannot update quotations after client views them (`viewed_by_client` flag) |
| **Atomic quotation acceptance** | Cloud Function batch-rejects all other quotations when one is accepted, no race conditions |
| **Role-based API access** | REST API enforces: clients manage their own jobs, workers manage their own quotations |
| **Non-root containers** | Call translate backend Docker image runs as non-root `voicesewa` user |

---

## PS 04 Bonus Features

| Bonus Requirement | Status | Implementation |
|---|---|---|
| **AI-Based Worker Matching** | Implemented | Geolocation (Haversine) + skill matching + rating sorting + AI demand forecast showing highest-demand service types by district and season |
| **Automatic Language Translation** | Implemented | Chat messages auto-translated to all 4 languages via N8N + Google Translate; live call translation via Google STT → Translate → TTS on Cloud Run |
| **Hybrid IVR Mode** | In Progress | N8N `Hybrid_IVR` workflow in development — job posting and acceptance through phone number-press menus for users with no smartphone/internet |
| **Repeat Booking & History** | Implemented | "Book Again" screen for one-tap re-booking; full job history with status filters; worker work history |
| **Verified Worker Profiles** | Implemented | Aadhaar QR verification, verified badge, rating system, review history |
| **AI Voice Bot** | Implemented | Google Gemini-backed conversational assistant with voice I/O in all 4 languages |

---

## End-to-End Feature Flows

### Job Booking Flow

```
[Client]
1. Opens app, taps "Post a Job" or speaks to VoiceBot
2. Selects service type (or VoiceBot detects from speech)
3. Adds description and address
4. Job created in Firestore (status: requested)
        ↓
[Firebase Function: notifyNearbyWorkers]
5. Geohash + skill match → multicast FCM to nearby workers
        ↓
[Workers]
6. Receive "New Job Nearby" push notification
7. Open job details, submit quotation (cost, time, availability)
        ↓
[Firebase Function: notifyClientOnNewQuotation]
8. Client receives FCM: "{workerName} submitted a quotation"
        ↓
[Client]
9. Reviews quotations, accepts one
        ↓
[Firebase Function: onQuotationAccepted]
10. Accepted worker: jobs.applied → jobs.confirmed
    Other workers: auto-rejected (batch write)
        ↓
[Firebase Functions: notifyWorkerOnQuotationStatus × N]
11. Accepted worker: "Quotation Accepted! 🎉"
    Others: "Quotation Auto-Rejected"
        ↓
[Worker]
12. Arrives at client's location
13. Client shows OTP; worker enters it to start job
14. Job status → inProgress
        ↓
[Notifications to both parties]
        ↓
15. Worker completes job, submits itemized bill
16. Client receives bill, marks completed
17. Client leaves feedback (star rating + comment)
        ↓
[Firebase Function: recalculateWorkerAvgRating]
18. Worker's avg_rating updated
```

### Voice Call with Translation Flow

```
[Client dials worker from job screen]
1. Call document created in Firestore (status: ringing)
        ↓
[N8N: Call_Notification or Firebase Function: sendCallNotification]
2. FCM push sent to worker: "Incoming call from client"
        ↓
[Worker]
3. Incoming call screen appears
4. Worker accepts → Firestore status → active
        ↓
[Auto Call Translate Backend (Cloud Run)]
5. Client: POST /session → sessionId
6. Both connect to wss://host/ws?sessionId=...&sourceLang=hi-IN&targetLang=en&voiceLang=en-IN
7. "call_started" event sent to both
        ↓
[Real-time per utterance]
8. Client speaks Hindi → binary PCM audio frames → server
9. Google STT → "नमस्ते, मुझे नल ठीक करवाना है"
10. Client UI shows live Hindi transcript
11. Google Translate → "Hello, I need to get the tap fixed"
12. Google TTS (en-IN Neural2) → PCM audio
13. Worker hears "Hello, I need to get the tap fixed" in English
14. Worker UI shows English transcript
        ↓ (same in reverse direction)
15. Worker speaks English → client hears Hindi
        ↓
16. Either party ends call → DELETE /session, Firestore status → ended
```

### AI Voice Bot Flow

```
[User taps VoiceBot tab]
1. Microphone activated (record package)
2. User speaks: "मुझे electrician चाहिए"
3. Audio recorded as base64
        ↓
[N8N Webhook: /webhook/chat]
4. POST { uid, audio (base64), type: 'client', lang: 'hi' }
        ↓
[N8N: VoiceSewa — Main Workflow]
5. Gemini processes request with user profile + session memory
6. Response: "ज़रूर! कृपया अपना पता बताएं और मैं आपके पास electricians ढूंढूंगा"
7. TTS service converts to Hindi audio
8. Return: { response: "...", base64Audio: "..." }
        ↓
[App]
9. Chat message displayed
10. Audio played back to user
11. App navigates to Create Job screen with service_type pre-filled
```

### Chat Translation Flow

```
[Worker sends message in Marathi]
1. Message written to Firestore:
  { originalMsg: "काम उद्या सकाळी सुरू होईल", is_worker: true, sent_at: now }
        ↓
[N8N: Chat_Translation Webhook]
2. Receives { originalMsg, jobId, quotationId, msgId }
3. Parallel: Google Translate → EN, HI, MR, GU
4. Upsert to Firestore message doc:
  translated: { en: "Work will start tomorrow morning", hi: "काम कल सुबह शुरू होगा", mr: "काम उद्या सकाळी सुरू होईल", gu: "..." }
        ↓
[Firebase Function: notifyClientOnNewMessage]
5. Client FCM: "{workerName} — Carpentry: Work will start tomorrow morning"
        ↓
[Client sees message in their language]
6. App reads translated.{userLocale} — displays in user's own language
```

---

## Setup & Running

### Prerequisites
- Flutter SDK 3.9.2+
- Python 3.11+
- Firebase project (Auth + Firestore + Messaging + Storage enabled)
- FlutterFire CLI
- GCP project (for Call Translate service)

### Client App

```bash
git clone -b client/main --single-branch https://github.com/aryan-madhavi/VoiceSewa.git VoiceSewa-Client

cd VoiceSewa-Client
flutter pub get
flutterfire configure          # generates lib/firebase_options.dart
flutter gen-l10n               # generates localization files
flutter run
```

### Worker App

```bash
git clone -b worker/main --single-branch https://github.com/aryan-madhavi/VoiceSewa.git VoiceSewa-Worker

cd VoiceSewa-Worker
flutter pub get
flutterfire configure
flutter gen-l10n
flutter run
```

### Auto Call Translation Backend

```bash
git clone -b backend/features/auto-translate-call --single-branch https://github.com/aryan-madhavi/VoiceSewa.git VoiceSewa-AutoCallTranslate

cd VoiceSewa-AutoCallTranslate
cp .env.example .env           # fill GOOGLE_CLOUD_PROJECT
npm install
node src/index.js              # local dev

# Deploy to Cloud Run
gcloud builds submit            # or push to trigger Cloud Build
```

### ML Forecast Service

```bash
git clone -b backend/node --single-branch https://github.com/aryan-madhavi/VoiceSewa.git VoiceSewa-NodeBackend

cd VoiceSewa-NodeBackend/ml
pip install -r requirements.txt
python app.py                   # or: gunicorn app:app
```

### Firebase Functions

```bash
git clone -b firebase/functions --single-branch https://github.com/aryan-madhavi/VoiceSewa.git VoiceSewa-FirebaseFunctions

cd VoiceSewa-FirebaseFunctions/functions
npm install
firebase deploy --only functions
```

### Aadhaar Service

```bash
cd VoiceSewa-FirebaseFunctions/aadhaar_service
pip install -r requirements.txt
apt-get install libzbar0 libgl1-mesa-glx
uvicorn main:app --host 0.0.0.0 --port $PORT
# Or deploy via render.yaml to Render.com
```

### Environment Variables Reference

**Call Translate Backend:**
- `GOOGLE_CLOUD_PROJECT` — GCP project ID
- `GOOGLE_APPLICATION_CREDENTIALS` — path to service account key (local only)
- `PORT` — default 8080

**N8N:** All API credentials (Google, Groq, Sarvam AI, Firebase) stored in N8N console credentials store — not in code.

---

*VoiceSewa is a dual-app system built for PS 04. This document covers all five repositories. Client app (`client/main`) and Worker app (`worker/main`) are separate Flutter projects sharing the same Firebase backend, call infrastructure, and automation layer.*
