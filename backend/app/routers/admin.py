from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_role
from app.models.user import User
from app.models.seller import Seller, DeliveryPartner
from app.models.product import Product, StockStatus
from app.models.category import Category
from app.models.order import Order, OrderStatus, PaymentStatus
from app.models.address import DeliveryZone
from app.models.tracking import AdminAction
from app.schemas.order import DeliveryZoneCreate

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    return {
        "orders": {
            "new": db.query(Order).filter(Order.status == OrderStatus.placed).count(),
            "processing": db.query(Order).filter(
                Order.status.in_([OrderStatus.accepted, OrderStatus.preparing, OrderStatus.delivery_assigned])
            ).count(),
            "out_for_delivery": db.query(Order).filter(Order.status == OrderStatus.out_for_delivery).count(),
            "delivered": db.query(Order).filter(Order.status == OrderStatus.delivered).count(),
            "cancelled": db.query(Order).filter(Order.status == OrderStatus.cancelled).count(),
        },
        "products": {
            "total": db.query(Product).count(),
            "categories": db.query(Category).filter(Category.is_active == True).count(),  # noqa: E712
            "other_products": db.query(Product).filter(Product.is_other == True).count(),  # noqa: E712
            "out_of_stock": db.query(Product).filter(Product.stock_status == StockStatus.out_of_stock).count(),
        },
        "users": {
            "customers": db.query(User).filter(User.role == "customer").count(),
            "sellers": db.query(Seller).count(),
            "delivery_partners": db.query(DeliveryPartner).count(),
        },
        "payments": {
            "paid": db.query(Order).filter(Order.payment_status == PaymentStatus.paid).count(),
            "cash_received": db.query(Order).filter(Order.payment_status == PaymentStatus.cash_received).count(),
            "pending": db.query(Order).filter(Order.payment_status == PaymentStatus.pending).count(),
            "unverified": db.query(Order).filter(Order.payment_status == PaymentStatus.unverified).count(),
        },
    }


@router.post("/sellers/{seller_id}/approve")
def approve_seller(seller_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    seller = db.query(Seller).filter(Seller.id == seller_id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Seller नहीं मिला।")
    seller.is_approved = True
    db.add(AdminAction(admin_user_id=admin.id, action="approve_seller", entity_type="seller", entity_id=seller.id, old_value="pending", new_value="approved"))
    db.commit()
    return {"message": "Seller approve हो गया।"}


@router.post("/delivery-partners/{dp_id}/approve")
def approve_delivery_partner(dp_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    dp = db.query(DeliveryPartner).filter(DeliveryPartner.id == dp_id).first()
    if not dp:
        raise HTTPException(status_code=404, detail="Delivery partner नहीं मिला।")
    dp.is_approved = True
    db.add(AdminAction(admin_user_id=admin.id, action="approve_delivery_partner", entity_type="delivery_partner", entity_id=dp.id, old_value="pending", new_value="approved"))
    db.commit()
    return {"message": "Delivery partner approve हो गया।"}


@router.post("/delivery-zones")
def add_delivery_zone(
    payload: DeliveryZoneCreate,
    db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"])),
):
    existing = db.query(DeliveryZone).filter(DeliveryZone.pincode == payload.pincode).first()
    if existing:
        existing.is_active = True
        existing.name = payload.name
        db.commit()
        db.refresh(existing)
        return existing

    zone = DeliveryZone(name=payload.name, pincode=payload.pincode, is_active=True)
    db.add(zone)
    db.commit()
    db.refresh(zone)
    return zone


@router.get("/audit-logs")
def audit_logs(db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    logs = db.query(AdminAction).order_by(AdminAction.timestamp.desc()).limit(200).all()
    return [
        {
            "admin_user_id": l.admin_user_id, "action": l.action, "entity_type": l.entity_type,
            "entity_id": l.entity_id, "old_value": l.old_value, "new_value": l.new_value,
            "timestamp": l.timestamp.isoformat(),
        }
        for l in logs
    ]
