FROM python:3.11-slim

# Install system dependencies needed by pyaadhaar (libzbar, opencv)
RUN apt-get update && apt-get install -y \
    libzbar0 \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

CMD uvicorn main:app --host 0.0.0.0 --port $PORT
