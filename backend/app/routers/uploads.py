import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_role
from app.models.user import User
from app.models.seller import Seller

router = APIRouter(prefix="/api/v1/uploads", tags=["uploads"])

# Stored alongside the backend app, served back out via StaticFiles mounted
# at /static in app/main.py. In production, point this at a real object
# store (S3, etc.) instead — kept as local disk here to match the existing
# SQLite-first, zero-external-dependency MVP approach.
UPLOAD_DIR = Path(__file__).resolve().parent.parent.parent / "static" / "products"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_UPLOAD_BYTES = 5 * 1024 * 1024  # 5 MB — rural/low-bandwidth friendly cap


@router.post("/product-image")
async def upload_product_image(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(require_role(["seller"])),
):
    """
    NEW endpoint — the backend previously only stored `image_url` as a
    plain string on Product, with no way for a client to actually upload
    a file and get a URL back. Seller must be an approved seller (checked
    the same way product-create already checks it) — an unapproved
    seller cannot even reach the product form that would use this.
    """
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller or not seller.is_approved:
        raise HTTPException(status_code=403, detail="आपकी shop अभी admin से approve नहीं हुई है।")

    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(status_code=400, detail="केवल JPEG/PNG/WebP image allowed है।")

    contents = await file.read()
    if len(contents) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=400, detail="Image 5MB से बड़ी नहीं हो सकती।")
    if not contents:
        raise HTTPException(status_code=400, detail="Empty file.")

    ext = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}[file.content_type]
    filename = f"seller{seller.id}_{uuid.uuid4().hex[:12]}{ext}"
    dest = UPLOAD_DIR / filename
    dest.write_bytes(contents)

    return {"image_url": f"/static/products/{filename}"}
