"""
Aadhaar QR Decode — FastAPI for Render.com
-------------------------------------------
POST /decode-aadhaar
Body: { "qr_data": "<raw string scanned from Aadhaar QR>" }
Uses: https://pypi.org/project/pyaadhaar/
"""

import base64
import json
import traceback

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pyaadhaar.decode import AadhaarOldQr, AadhaarSecureQr

app = FastAPI(title="Aadhaar QR Decode Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST", "OPTIONS"],
    allow_headers=["*"],
)


class QrRequest(BaseModel):
    qr_data: str


@app.get("/")
async def health():
    return {"status": "ok"}


@app.post("/decode-aadhaar")
async def decode_aadhaar(req: QrRequest):
    qr_data = req.qr_data.strip()

    if not qr_data:
        return {"success": False, "error": "qr_data is required"}

    try:
        is_secure = qr_data.isdigit() and len(qr_data) > 100
        obj = AadhaarSecureQr(qr_data) if is_secure else AadhaarOldQr(qr_data)
        data: dict = obj.decodeddata()

        # Extract photo
        photo_b64 = None
        try:
            photo_bytes = obj.image()
            if photo_bytes:
                photo_b64 = base64.b64encode(photo_bytes).decode("utf-8")
        except Exception:
            pass

        # Build address
        addr_parts = [
            data.get("house"), data.get("street"), data.get("lm"),
            data.get("loc"), data.get("vtc"), data.get("po"),
            data.get("subdist"), data.get("dist"), data.get("state"),
            data.get("pc"),
        ]
        address = ", ".join(
            p for p in addr_parts if p and p.strip() not in ["-", ""]
        )

        # Mask UID — last 4 only
        uid_full: str = data.get("uid", "")
        uid_last4 = uid_full[-4:] if uid_full else None

        return {
            "success": True,
            "name": data.get("name"),
            "gender": data.get("gender"),
            "dob": data.get("dob"),
            "year_of_birth": data.get("yob"),
            "address": address or None,
            "state": data.get("state"),
            "district": data.get("dist"),
            "pincode": data.get("pc"),
            "uid_last4": uid_last4,
            "photo_base64": photo_b64,
            "is_secure_qr": is_secure,
        }

    except Exception as e:
        traceback.print_exc()
        return {"success": False, "error": f"Failed to decode QR: {str(e)}"}
