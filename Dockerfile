# ── Deps stage ────────────────────────────────────────────────────────────────
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev --ignore-scripts

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM node:22-alpine AS runtime
WORKDIR /app

# Non-root user (Cloud Run security best practice)
RUN addgroup -S voicesewa && adduser -S voicesewa -G voicesewa

COPY --from=deps /app/node_modules ./node_modules
COPY src/ ./src/
COPY package.json ./

USER voicesewa

# Cloud Run injects PORT=8080 automatically
ENV NODE_ENV=production

EXPOSE 8080

CMD ["node", "src/index.js"]