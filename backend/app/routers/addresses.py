from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_role
from app.models.user import User
from app.models.address import Address, DeliveryZone
from app.schemas.order import AddressCreate, AddressOut

router = APIRouter(prefix="/api/v1/addresses", tags=["addresses"])


@router.get("", response_model=list[AddressOut])
def list_addresses(db: Session = Depends(get_db), user: User = Depends(require_role(["customer"]))):
    return db.query(Address).filter(Address.customer_id == user.id).all()


@router.post("", response_model=AddressOut)
def add_address(
    payload: AddressCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(["customer"])),
):
    # Local delivery-zone check (requirement #26) — only allow addresses
    # inside an active delivery zone.
    zone = db.query(DeliveryZone).filter(
        DeliveryZone.pincode == payload.pincode, DeliveryZone.is_active == True  # noqa: E712
    ).first()
    if not zone:
        raise HTTPException(status_code=400, detail="अभी हम इस area में delivery नहीं करते हैं।")

    address = Address(customer_id=user.id, **payload.model_dump())
    db.add(address)
    db.commit()
    db.refresh(address)
    return address


@router.put("/{address_id}", response_model=AddressOut)
def update_address(
    address_id: int,
    payload: AddressCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(["customer"])),
):
    address = db.query(Address).filter(Address.id == address_id, Address.customer_id == user.id).first()
    if not address:
        raise HTTPException(status_code=404, detail="Address नहीं मिला।")

    # Same zone check as create — otherwise a customer could bypass it by
    # creating a valid address then editing the pincode afterward.
    zone = db.query(DeliveryZone).filter(
        DeliveryZone.pincode == payload.pincode, DeliveryZone.is_active == True  # noqa: E712
    ).first()
    if not zone:
        raise HTTPException(status_code=400, detail="अभी हम इस area में delivery नहीं करते हैं।")

    for field, value in payload.model_dump().items():
        setattr(address, field, value)
    db.commit()
    db.refresh(address)
    return address


@router.delete("/{address_id}")
def delete_address(
    address_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(["customer"])),
):
    address = db.query(Address).filter(Address.id == address_id, Address.customer_id == user.id).first()
    if not address:
        raise HTTPException(status_code=404, detail="Address नहीं मिला।")
    db.delete(address)
    db.commit()
    return {"message": "Address हटा दिया गया।"}
