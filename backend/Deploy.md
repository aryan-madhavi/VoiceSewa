# Backend Deployment Guide

## Overview

The backend is a single Node.js process (Express + WebSocketServer on the same port) that requires:
- A **Firebase service account** (for Admin SDK / token verification)
- A **Google Cloud service account** with STT, Translation, and TTS APIs enabled (can be the same account)
- Environment variables: `GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_CLOUD_PROJECT`, `PORT`

The service account JSON file path is read at startup via `GOOGLE_APPLICATION_CREDENTIALS`.

---

## Recommended Platform: Google Cloud Run

Cloud Run is the simplest fit — it handles HTTPS/WSS termination, auto-scaling, and is in the same project as the GCP APIs.

### 1. Enable Required APIs

```bash
gcloud services enable \
  speech.googleapis.com \
  translate.googleapis.com \
  texttospeech.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  --project=voicesewa
```

### 2. Create a Service Account

```bash
gcloud iam service-accounts create voicesewa-backend \
  --display-name="VoiceSewa Backend" \
  --project=voicesewa

# Grant the three GCP API roles
gcloud projects add-iam-policy-binding voicesewa \
  --member="serviceAccount:voicesewa-backend@voicesewa.iam.gserviceaccount.com" \
  --role="roles/speech.client"

gcloud projects add-iam-policy-binding voicesewa \
  --member="serviceAccount:voicesewa-backend@voicesewa.iam.gserviceaccount.com" \
  --role="roles/cloudtranslate.user"

gcloud projects add-iam-policy-binding voicesewa \
  --member="serviceAccount:voicesewa-backend@voicesewa.iam.gserviceaccount.com" \
  --role="roles/cloudtexttospeech.user"
```

### 3. Create and Download a Key (for GOOGLE_APPLICATION_CREDENTIALS)

```bash
gcloud iam service-accounts keys create secrets/serviceAccountKey.json \
  --iam-account=voicesewa-backend@voicesewa.iam.gserviceaccount.com
```

> The Firebase Admin SDK also uses this key. Ensure the Firebase project's service account has `roles/firebase.admin` or at minimum `roles/firebaseauth.admin`.

### 4. Store the Key as a Secret Manager Secret

Avoid baking the JSON into the image. Use Secret Manager instead:

```bash
gcloud secrets create voicesewa-sa-key \
  --data-file=secrets/serviceAccountKey.json \
  --project=voicesewa

# Grant Cloud Run's SA access to the secret
gcloud secrets add-iam-policy-binding voicesewa-sa-key \
  --member="serviceAccount:voicesewa-backend@voicesewa.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=voicesewa
```

### 5. Create Artifact Registry Repository (once)

```bash
gcloud artifacts repositories create voicesewa \
  --repository-format=docker \
  --location=asia-south1 \
  --project=voicesewa
```

### 6. Grant Cloud Build the Required IAM Roles (once)

Cloud Build's default service account needs permission to deploy to Cloud Run and read secrets:

```bash
PROJECT_NUMBER=$(gcloud projects describe voicesewa --format='value(projectNumber)')

gcloud projects add-iam-policy-binding voicesewa \
  --member="serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding voicesewa \
  --member="serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding voicesewa \
  --member="serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### 7. Deploy via Cloud Build

The `cloudbuild.yaml` at the root of `backend/` handles build, push, and deploy in one command:

```bash
# Manual trigger from backend/
gcloud builds submit --project=voicesewa

# Or trigger on every push to main by connecting the repo in the
# Cloud Build console: Cloud Build → Triggers → Connect Repository
```

Each build tags the image with both `$COMMIT_SHA` (immutable, for rollback) and `latest`.

To roll back to a previous commit:

```bash
gcloud run deploy voicesewa-backend \
  --image=asia-south1-docker.pkg.dev/voicesewa/voicesewa/backend:<COMMIT_SHA> \
  --region=asia-south1 \
  --project=voicesewa
```

> **`--timeout=3600`** is critical — WebSocket connections for active calls can last up to 2 hours. Cloud Run's maximum request timeout is 3600s.

> `--min-instances=0` means cold starts are possible. Set `--min-instances=1` if call setup latency is a concern.

### 7. Update Flutter App Constants

After deploy, copy the Cloud Run service URL and set it in `app/lib/core/constants.dart`:

```dart
static const backendUrl = 'https://voicesewa-backend-xxxx-as.a.run.app';
static const backendWsUrl = 'wss://voicesewa-backend-xxxx-as.a.run.app';
```

Cloud Run terminates TLS, so use `https://` for REST and `wss://` for WebSocket — no self-signed cert handling needed on the client.

---

---

## Railway Deployment (recommended for early/moderate scale)

Railway deploys directly from GitHub, uses the existing `Dockerfile`, and injects environment variables from the dashboard — no Secret Manager, no Artifact Registry, no IAM setup.

### 1. Create a Railway project

1. Go to [railway.app](https://railway.app) → New Project → Deploy from GitHub repo
2. Select this repository and set the **Root Directory** to `backend/`
3. Railway detects `Dockerfile` automatically (configured in `railway.json`)

### 2. Set environment variables in the Railway dashboard

Go to your service → **Variables** and add:

| Variable | Value |
|---|---|
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Full contents of your service account JSON key file |
| `GOOGLE_CLOUD_PROJECT` | `voicesewa` |

`PORT` is injected by Railway automatically — do not set it.

To get the service account JSON:
```bash
gcloud iam service-accounts keys create /tmp/key.json \
  --iam-account=voicesewa-backend@voicesewa.iam.gserviceaccount.com
cat /tmp/key.json   # paste the full output into the Railway variable
```

The service account needs the same IAM roles as the Cloud Run setup (step 2 above).

### 3. Generate a domain

Railway service → **Settings → Networking → Generate Domain**

You'll get a URL like `https://voicesewa-backend-production.up.railway.app`. Use this as `BACKEND_URL` when building the Flutter app.

### 4. Deploy

Every push to your connected branch triggers a redeploy automatically. To deploy manually:

```bash
# Install Railway CLI
npm install -g @railway/cli

# From backend/
railway login
railway up
```

### 5. Update Flutter app

```bash
flutter build apk \
  --dart-define=BACKEND_URL=https://voicesewa-backend-production.up.railway.app
```

See `app/lib/core/constants.dart` for full build instructions.

---

## Local Development

```bash
# From backend/
cp secrets/serviceAccountKey.json secrets/serviceAccountKey.json  # already there
export GOOGLE_APPLICATION_CREDENTIALS=./secrets/serviceAccountKey.json
export GOOGLE_CLOUD_PROJECT=voicesewa
export PORT=8080
npm run dev
```

Point the Flutter app at `http://10.0.2.2:8080` (Android emulator) or your machine's LAN IP for a physical device.

---

## Environment Variables Reference

| Variable | Example | Required |
|---|---|---|
| `GOOGLE_APPLICATION_CREDENTIALS` | `/secrets/sa-key.json` | Yes |
| `GOOGLE_CLOUD_PROJECT` | `voicesewa` | Yes |
| `PORT` | `8080` | No (defaults to 8080) |

---

## Scaling Notes

- Each active call holds **2 open WebSocket connections** and **2 STT streaming sessions** (one per direction). Each STT stream is a persistent gRPC connection to Google.
- Cloud Run's concurrency is set to 80; with large audio payloads, a lower value (e.g. 20–40) may be safer if memory pressure is observed.
- The in-memory session store does **not** survive restarts or scale across multiple instances. If you need multi-instance scaling, replace `sessionManager.js` with a Redis-backed store (e.g. via Cloud Memorystore).
- STT streams auto-restart every 270s (before Google's 290s limit). Restarts are per-connection and transparent to the caller.
