from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.core.database import get_db
from app.models.product import Product, ProductKeyword
from app.models.category import Category
from app.schemas.product import ProductOut

router = APIRouter(prefix="/api/v1/search", tags=["search"])


@router.get("", response_model=list[ProductOut])
def smart_search(q: str = Query(..., min_length=1), db: Session = Depends(get_db)):
    """
    Text search used by BOTH the typed search box and voice search (the
    Android/browser speech-recognition result is sent here as plain text
    — requirement #58/critical voice workflow). Ranking, per requirement
    #11:
      1. exact product name match
      2. product name contains query
      3. keyword match
      4. category name match
      5. (related — kept simple in MVP: same as keyword match, de-duped)

    Security note (requirement #14): every filter below uses SQLAlchemy's
    `.ilike()` as a bound query parameter — the f-string only builds the
    *value* that gets bound, it is never concatenated into raw SQL text,
    so this is not vulnerable to SQL injection. No raw `.execute(f"...")`
    or string-built SQL exists anywhere in this codebase.
    """
    q_clean = q.strip()
    if not q_clean:
        return []

    base = db.query(Product).filter(Product.is_active == True)  # noqa: E712

    exact = base.filter(Product.name.ilike(q_clean)).all()

    name_match = (
        base.filter(Product.name.ilike(f"%{q_clean}%"))
        .filter(~Product.id.in_([p.id for p in exact]) if exact else True)
        .all()
    )

    keyword_product_ids = [
        row.product_id
        for row in db.query(ProductKeyword.product_id)
        .filter(ProductKeyword.keyword.ilike(f"%{q_clean}%"))
        .distinct()
    ]
    already = {p.id for p in exact + name_match}
    keyword_match = (
        base.filter(Product.id.in_(keyword_product_ids))
        .filter(~Product.id.in_(already) if already else True)
        .all()
        if keyword_product_ids else []
    )

    already |= {p.id for p in keyword_match}
    category_ids = [
        c.id for c in db.query(Category).filter(
            or_(Category.name_hi.ilike(f"%{q_clean}%"), Category.name_en.ilike(f"%{q_clean}%"))
        )
    ]
    category_match = (
        base.filter(Product.category_id.in_(category_ids))
        .filter(~Product.id.in_(already) if already else True)
        .all()
        if category_ids else []
    )

    return exact + name_match + keyword_match + category_match
