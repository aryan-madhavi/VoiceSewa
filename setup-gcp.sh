#!/bin/bash
# setup-gcp.sh
#
# One-time setup script — run this ONCE from your local machine.
# After this, all future deploys are automatic via Cloud Build on git push.
#
# Usage:
#   chmod +x setup-gcp.sh
#   ./setup-gcp.sh

set -e  # Exit on any error

# ── Config — edit these ───────────────────────────────────────────────────────
PROJECT_ID="voicesewa"    # ← replace with your Firebase/GCP project ID
REGION="asia-south1"                # Mumbai — best latency for India
SERVICE_NAME="voicesewa-call-translate"
SA_NAME="voicesewa-call-translate"       # Service account name

echo ""
echo "🚀 VoiceSewa Cloud Run Setup"
echo "   Project : $PROJECT_ID"
echo "   Region  : $REGION"
echo "   Service : $SERVICE_NAME"
echo ""

# ── 1. Set active project ─────────────────────────────────────────────────────
gcloud config set project "$PROJECT_ID"

# ── 2. Enable required APIs ───────────────────────────────────────────────────
echo "📦 Enabling APIs..."
gcloud services enable \
  run.googleapis.com \
  speech.googleapis.com \
  translate.googleapis.com \
  texttospeech.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  firebase.googleapis.com

# ── 3. Create Artifact Registry repo for Docker images ───────────────────────
echo "🗂  Creating Artifact Registry repository..."
gcloud artifacts repositories create voicesewa \
  --repository-format=docker \
  --location="$REGION" \
  --description="VoiceSewa Docker images" \
  2>/dev/null || echo "   (repo already exists — skipping)"

# ── 4. Create dedicated service account ───────────────────────────────────────
echo "🔑 Creating service account..."
gcloud iam service-accounts create "$SA_NAME" \
  --display-name="VoiceSewa Translate Service" \
  2>/dev/null || echo "   (service account already exists — skipping)"

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# ── 5. Grant IAM roles to the service account ────────────────────────────────
echo "🔐 Granting IAM roles..."

ROLES=(
  "roles/speech.client"           # Google STT
  "roles/cloudtranslate.user"     # Google Translate
  "roles/texttospeech.client"     # Google TTS (correct role for user-created SAs)
  "roles/firebaseauth.admin"      # Firebase token verification with revocation check
)

for ROLE in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$ROLE" \
    --quiet
  echo "   ✓ $ROLE"
done

# ── 6. Grant Cloud Build permission to deploy Cloud Run ───────────────────────
echo "🏗  Granting Cloud Build deploy permissions..."
CB_SA="${PROJECT_ID}@cloudbuild.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CB_SA}" \
  --role="roles/run.admin" --quiet

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CB_SA}" \
  --role="roles/iam.serviceAccountUser" --quiet

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CB_SA}" \
  --role="roles/artifactregistry.writer" --quiet

# ── 7. Create local .env for development ─────────────────────────────────────
if [ ! -f ".env" ]; then
  echo ""
  echo "📝 Creating .env for local development..."
  cat > .env << ENVEOF
GOOGLE_APPLICATION_CREDENTIALS=./secrets/gcloud-key.json
GOOGLE_CLOUD_PROJECT=${PROJECT_ID}
PORT=8080
ENVEOF

  mkdir -p secrets
  gcloud iam service-accounts keys create secrets/gcloud-key.json \
    --iam-account="$SA_EMAIL"
  echo "   ✓ Key saved to secrets/gcloud-key.json (never commit this!)"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Go to GCP Console → Cloud Build → Triggers"
echo "  2. Click 'Connect Repository' → select aryan-madhavi/VoiceSewa"
echo "  3. Create trigger:"
echo "     - Event              : Push to a branch"
echo "     - Branch (regex)     : ^backend/features/auto-translate-call$"
echo "     - Included files     : auto-translate-call/**"
echo "     - Config             : auto-translate-call/cloudbuild.yaml"
echo "     - Substitutions:"
echo "         _REGION       = $REGION"
echo "         _SERVICE_NAME = $SERVICE_NAME"
echo ""
echo "  After that, every git push to main auto-deploys to Cloud Run! 🎉"
echo ""
echo "  To deploy manually right now:"
echo "    gcloud builds submit --config cloudbuild.yaml \\"
echo "      --substitutions=_REGION=$REGION,_SERVICE_NAME=$SERVICE_NAME"
echo ""