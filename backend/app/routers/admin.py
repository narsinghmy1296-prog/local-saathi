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
from app.schemas.admin import SellerOut, DeliveryPartnerOut

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


def _seller_out(db: Session, seller: Seller) -> dict:
    return {
        "id": seller.id,
        "user_id": seller.user_id,
        "shop_name": seller.shop_name,
        "owner_name": seller.owner_name,
        "area": seller.area,
        "upi_id": seller.upi_id,
        "is_approved": seller.is_approved,
        "phone": seller.user.phone if seller.user else "",
        "is_account_active": seller.user.is_active if seller.user else False,
        "product_count": db.query(Product).filter(Product.seller_id == seller.id).count(),
    }


def _dp_out(dp: DeliveryPartner) -> dict:
    return {
        "id": dp.id,
        "user_id": dp.user_id,
        "name": dp.user.name if dp.user else "",
        "phone": dp.user.phone if dp.user else "",
        "vehicle_type": dp.vehicle_type,
        "area": dp.area,
        "is_approved": dp.is_approved,
        "is_available": dp.is_available,
        "is_account_active": dp.user.is_active if dp.user else False,
    }


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


@router.get("/sellers", response_model=list[SellerOut])
def list_sellers(
    status: str = "all",  # all | pending | approved
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["admin"])),
):
    """
    NEW (Admin Panel prerequisite — did not exist before): list/search
    sellers for the Seller Management screen. There was previously no way
    for an admin client to even discover a seller_id to approve; only a
    single approve-by-id action existed.
    """
    query = db.query(Seller)
    if status == "pending":
        query = query.filter(Seller.is_approved == False)  # noqa: E712
    elif status == "approved":
        query = query.filter(Seller.is_approved == True)  # noqa: E712
    return [_seller_out(db, s) for s in query.all()]


@router.get("/sellers/{seller_id}", response_model=SellerOut)
def get_seller(seller_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    seller = db.query(Seller).filter(Seller.id == seller_id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Seller नहीं मिला।")
    return _seller_out(db, seller)


@router.post("/sellers/{seller_id}/approve")
def approve_seller(seller_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    seller = db.query(Seller).filter(Seller.id == seller_id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Seller नहीं मिला।")
    seller.is_approved = True
    db.add(AdminAction(admin_user_id=admin.id, action="approve_seller", entity_type="seller", entity_id=seller.id, old_value="pending", new_value="approved"))
    db.commit()
    return {"message": "Seller approve हो गया।"}


@router.post("/sellers/{seller_id}/reject")
def reject_seller(seller_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    """
    NEW — rejecting a seller registration. There is no separate
    "rejected" column on Seller (kept the schema unchanged), so a
    rejection is modeled as: not approved + the login account disabled,
    which matches requirement #40 ("clear approval/pending/rejected
    account status") from the seller's point of view — a rejected seller
    simply cannot log in, and never shows up as "pending" again because
    the client filters on is_account_active too.
    """
    seller = db.query(Seller).filter(Seller.id == seller_id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Seller नहीं मिला।")
    seller.is_approved = False
    if seller.user:
        seller.user.is_active = False
    db.add(AdminAction(admin_user_id=admin.id, action="reject_seller", entity_type="seller", entity_id=seller.id, old_value="pending", new_value="rejected"))
    db.commit()
    return {"message": "Seller reject कर दिया गया।"}


@router.post("/sellers/{seller_id}/deactivate")
def deactivate_seller(seller_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    """NEW — suspend an already-approved seller's login without touching their products/order history."""
    seller = db.query(Seller).filter(Seller.id == seller_id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Seller नहीं मिला।")
    if seller.user:
        seller.user.is_active = False
    db.add(AdminAction(admin_user_id=admin.id, action="deactivate_seller", entity_type="seller", entity_id=seller.id, old_value="active", new_value="inactive"))
    db.commit()
    return {"message": "Seller निष्क्रिय कर दिया गया।"}


@router.post("/sellers/{seller_id}/activate")
def activate_seller(seller_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    """NEW — reinstate a previously deactivated/rejected seller's login (does not by itself re-approve them)."""
    seller = db.query(Seller).filter(Seller.id == seller_id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Seller नहीं मिला।")
    if seller.user:
        seller.user.is_active = True
    db.add(AdminAction(admin_user_id=admin.id, action="activate_seller", entity_type="seller", entity_id=seller.id, old_value="inactive", new_value="active"))
    db.commit()
    return {"message": "Seller फिर से active कर दिया गया।"}


@router.get("/delivery-partners", response_model=list[DeliveryPartnerOut])
def list_delivery_partners(
    status: str = "all",
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["admin"])),
):
    """NEW (Admin Panel prerequisite) — mirrors /admin/sellers above for delivery partners."""
    query = db.query(DeliveryPartner)
    if status == "pending":
        query = query.filter(DeliveryPartner.is_approved == False)  # noqa: E712
    elif status == "approved":
        query = query.filter(DeliveryPartner.is_approved == True)  # noqa: E712
    return [_dp_out(dp) for dp in query.all()]


@router.post("/delivery-partners/{dp_id}/approve")
def approve_delivery_partner(dp_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    dp = db.query(DeliveryPartner).filter(DeliveryPartner.id == dp_id).first()
    if not dp:
        raise HTTPException(status_code=404, detail="Delivery partner नहीं मिला।")
    dp.is_approved = True
    db.add(AdminAction(admin_user_id=admin.id, action="approve_delivery_partner", entity_type="delivery_partner", entity_id=dp.id, old_value="pending", new_value="approved"))
    db.commit()
    return {"message": "Delivery partner approve हो गया।"}


@router.post("/delivery-partners/{dp_id}/reject")
def reject_delivery_partner(dp_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    dp = db.query(DeliveryPartner).filter(DeliveryPartner.id == dp_id).first()
    if not dp:
        raise HTTPException(status_code=404, detail="Delivery partner नहीं मिला।")
    dp.is_approved = False
    if dp.user:
        dp.user.is_active = False
    db.add(AdminAction(admin_user_id=admin.id, action="reject_delivery_partner", entity_type="delivery_partner", entity_id=dp.id, old_value="pending", new_value="rejected"))
    db.commit()
    return {"message": "Delivery partner reject कर दिया गया।"}


@router.post("/delivery-partners/{dp_id}/deactivate")
def deactivate_delivery_partner(dp_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    dp = db.query(DeliveryPartner).filter(DeliveryPartner.id == dp_id).first()
    if not dp:
        raise HTTPException(status_code=404, detail="Delivery partner नहीं मिला।")
    if dp.user:
        dp.user.is_active = False
    db.add(AdminAction(admin_user_id=admin.id, action="deactivate_delivery_partner", entity_type="delivery_partner", entity_id=dp.id, old_value="active", new_value="inactive"))
    db.commit()
    return {"message": "Delivery partner निष्क्रिय कर दिया गया।"}


@router.post("/delivery-partners/{dp_id}/activate")
def activate_delivery_partner(dp_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role(["admin"]))):
    dp = db.query(DeliveryPartner).filter(DeliveryPartner.id == dp_id).first()
    if not dp:
        raise HTTPException(status_code=404, detail="Delivery partner नहीं मिला।")
    if dp.user:
        dp.user.is_active = True
    db.add(AdminAction(admin_user_id=admin.id, action="activate_delivery_partner", entity_type="delivery_partner", entity_id=dp.id, old_value="inactive", new_value="active"))
    db.commit()
    return {"message": "Delivery partner फिर से active कर दिया गया।"}


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
