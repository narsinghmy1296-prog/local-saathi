from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_role
from app.models.user import User
from app.models.seller import Seller
from app.models.tracking import AdminAction

router = APIRouter(prefix="/api/v1/sellers", tags=["sellers"])


class SellerMeOut(BaseModel):
    id: int
    shop_name: str
    owner_name: str
    area: str
    upi_id: str | None
    is_approved: bool
    phone: str
    name: str

    class Config:
        from_attributes = True


class SellerMeUpdate(BaseModel):
    """
    All optional — seller sends only what changes. Approval status is
    intentionally NOT editable here (admin-only, via /admin/sellers/*).
    """
    shop_name: str | None = Field(None, min_length=1, max_length=150)
    owner_name: str | None = Field(None, min_length=1, max_length=100)
    area: str | None = Field(None, min_length=1, max_length=150)
    upi_id: str | None = Field(None, max_length=100)


def _get_own_seller(db: Session, user: User) -> Seller:
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Seller profile नहीं मिली।")
    return seller


@router.get("/me", response_model=SellerMeOut)
def get_my_profile(db: Session = Depends(get_db), user: User = Depends(require_role(["seller"]))):
    seller = _get_own_seller(db, user)
    return SellerMeOut(
        id=seller.id, shop_name=seller.shop_name, owner_name=seller.owner_name,
        area=seller.area, upi_id=seller.upi_id, is_approved=seller.is_approved,
        phone=user.phone, name=user.name,
    )


@router.put("/me", response_model=SellerMeOut)
def update_my_profile(
    payload: SellerMeUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(["seller"])),
):
    seller = _get_own_seller(db, user)
    changes = payload.model_dump(exclude_unset=True)
    old_value = f"{seller.shop_name}|{seller.area}"
    for field, value in changes.items():
        setattr(seller, field, value)
    db.add(AdminAction(
        admin_user_id=user.id, action="seller_self_update_profile",
        entity_type="seller", entity_id=seller.id,
        old_value=old_value, new_value=f"{seller.shop_name}|{seller.area}",
    ))
    db.commit()
    db.refresh(seller)
    return SellerMeOut(
        id=seller.id, shop_name=seller.shop_name, owner_name=seller.owner_name,
        area=seller.area, upi_id=seller.upi_id, is_approved=seller.is_approved,
        phone=user.phone, name=user.name,
    )
