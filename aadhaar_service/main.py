"""
Aadhaar QR Decode — Firebase Cloud Function (Python)
------------------------------------------------------
POST https://<region>-<project-id>.cloudfunctions.net/decodeAadhaar
Body: { "qr_data": "<raw string scanned from Aadhaar QR>" }
Uses: https://pypi.org/project/pyaadhaar/
"""

import base64
import json
import traceback

from firebase_functions import https_fn, options
from pyaadhaar.decode import AadhaarOldQr, AadhaarSecureQr


# ── CORS helper ────────────────────────────────────────────────────────────

def _cors_headers():
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
        "Content-Type": "application/json",
    }


def _json_response(data: dict, status: int = 200) -> https_fn.Response:
    return https_fn.Response(
        json.dumps(data),
        status=status,
        headers=_cors_headers(),
    )


# ── Main function ──────────────────────────────────────────────────────────

@https_fn.on_request(timeout_sec=120, memory=options.MemoryOption.MB_512, min_instances=0)
def decodeAadhaar(req: https_fn.Request) -> https_fn.Response:
    """
    Decodes Aadhaar QR data using pyaadhaar.
    Supports Secure QR (new cards) and Old QR (older cards).
    Never returns full UID — only last 4 digits (UIDAI legal requirement).
    """

    # Handle CORS preflight
    if req.method == "OPTIONS":
        return _json_response({}, 204)

    if req.method != "POST":
        return _json_response({"success": False, "error": "Only POST allowed"}, 405)

    # ── Parse request body ─────────────────────────────────────────────────
    try:
        body = req.get_json(silent=True) or {}
        qr_data = str(body.get("qr_data", "")).strip()
    except Exception:
        return _json_response({"success": False, "error": "Invalid JSON body"}, 400)

    if not qr_data:
        return _json_response({"success": False, "error": "qr_data is required"}, 400)

    # ── Decode QR ──────────────────────────────────────────────────────────
    try:
        # Secure QR: large all-numeric string (new format post-2019)
        # Old QR:    XML-based shorter string (older Aadhaar cards)
        is_secure = qr_data.isdigit() and len(qr_data) > 100

        obj = AadhaarSecureQr(qr_data) if is_secure else AadhaarOldQr(qr_data)
        data: dict = obj.decodeddata()

        # ── Extract photo (Secure QR only) ─────────────────────────────────
        photo_b64 = None
        try:
            photo_bytes = obj.image()
            if photo_bytes:
                photo_b64 = base64.b64encode(photo_bytes).decode("utf-8")
        except Exception:
            pass  # photo not available in old QR format

        # ── Build readable address string ──────────────────────────────────
        addr_parts = [
            data.get("house"),
            data.get("street"),
            data.get("lm"),
            data.get("loc"),
            data.get("vtc"),
            data.get("po"),
            data.get("subdist"),
            data.get("dist"),
            data.get("state"),
            data.get("pc"),
        ]
        address = ", ".join(
            p for p in addr_parts if p and p.strip() not in ["-", ""]
        )

        # ── Mask UID — only last 4 digits ──────────────────────────────────
        uid_full: str = data.get("uid", "")
        uid_last4 = uid_full[-4:] if uid_full else None

        return _json_response({
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
        })

    except Exception as e:
        traceback.print_exc()
        return _json_response({
            "success": False,
            "error": f"Failed to decode QR: {str(e)}",
        }, 500)