
  # VoiceSewa 

  Multilingual Voice-Assisted Job Connection Platform for Blue-Collar Services

```
auto-translate-call/
│
├── src/
│   ├── index.js              # Entry point — boots HTTP + WebSocket server
│   ├── firebaseAuth.js       # Firebase Admin SDK — token verification middleware
│   ├── wsHandler.js          # WebSocket connections — routes audio between users
│   ├── routes.js             # REST API — POST /session, GET /health, etc.
│   ├── sessionManager.js     # In-memory session store with TTL auto-cleanup
│   └── translationSession.js # Google STT → Translate → TTS pipeline per user
│
├── secrets/                  # ⚠️ Local dev only — never commit
│   └── gcloud-key.json       # GCP service account key (gitignored)
│
├── .env                      # Local env vars (gitignored)
├── .env.example              # Template to copy from
├── .gitignore
├── package.json
├── Dockerfile                # Cloud Run optimised, non-root user
├── cloudbuild.yaml           # CI/CD — auto-deploy on git push to main
├── setup-gcp.sh              # One-time GCP setup script
└── README.md
```