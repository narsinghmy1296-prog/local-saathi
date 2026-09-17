from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_role
from app.models.category import Category
from app.models.user import User
from app.models.tracking import AdminAction
from app.schemas.product import CategoryCreate, CategoryOut

router = APIRouter(prefix="/api/v1/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    """Public — anyone browsing the app can see active categories, sorted."""
    return (
        db.query(Category)
        .filter(Category.is_active == True)  # noqa: E712
        .order_by(Category.sort_order.asc())
        .all()
    )


@router.post("", response_model=CategoryOut)
def create_category(
    payload: CategoryCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["admin"])),
):
    category = Category(**payload.model_dump())
    db.add(category)
    db.commit()
    db.refresh(category)

    db.add(AdminAction(
        admin_user_id=admin.id, action="create_category",
        entity_type="category", entity_id=category.id,
        old_value=None, new_value=category.name_en,
    ))
    db.commit()
    return category


@router.put("/{category_id}", response_model=CategoryOut)
def update_category(
    category_id: int,
    payload: CategoryCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["admin"])),
):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category नहीं मिली।")

    old_value = f"{category.name_en}"
    for field, value in payload.model_dump().items():
        setattr(category, field, value)
    db.commit()
    db.refresh(category)

    db.add(AdminAction(
        admin_user_id=admin.id, action="update_category",
        entity_type="category", entity_id=category.id,
        old_value=old_value, new_value=category.name_en,
    ))
    db.commit()
    return category


@router.delete("/{category_id}")
def deactivate_category(
    category_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["admin"])),
):
    """Soft-delete only — never hard-delete a category with live products."""
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category नहीं मिली।")
    category.is_active = False
    db.commit()

    db.add(AdminAction(
        admin_user_id=admin.id, action="deactivate_category",
        entity_type="category", entity_id=category.id,
        old_value="active", new_value="inactive",
    ))
    db.commit()
    return {"message": "Category निष्क्रिय कर दी गई।"}
