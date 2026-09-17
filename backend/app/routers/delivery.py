from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_role
from app.core.state_machine import is_delivery_transition_allowed, is_order_transition_allowed
from app.models.user import User
from app.models.seller import DeliveryPartner
from app.models.tracking import Delivery, DeliveryStatus, DeliveryStatusHistory
from app.models.order import Order, OrderStatus, OrderStatusHistory
from app.schemas.order import OrderStatusUpdate
from datetime import datetime

router = APIRouter(prefix="/api/v1/delivery", tags=["delivery"])


@router.get("/assignments")
def my_assignments(db: Session = Depends(get_db), user: User = Depends(require_role(["delivery"]))):
    dp = db.query(DeliveryPartner).filter(DeliveryPartner.user_id == user.id).first()
    if not dp:
        raise HTTPException(status_code=404, detail="Delivery partner profile नहीं मिली।")

    deliveries = db.query(Delivery).filter(Delivery.delivery_partner_id == dp.id).all()
    result = []
    for d in deliveries:
        order = db.query(Order).filter(Order.id == d.order_id).first()
        if not order:
            continue
        result.append({
            "delivery_id": d.id,
            "order_id": order.id,
            "delivery_status": d.status.value,
            "order_status": order.status.value,
            "customer_name": order.customer.name if order.customer else None,
            "address": {
                "village_town": order.address.village_town,
                "house": order.address.house,
                "landmark": order.address.landmark,
                "pincode": order.address.pincode,
                "mobile": order.address.mobile,
            } if order.address else None,
            "payment_method": order.payment_method.value,
            "payment_status": order.payment_status.value,
            "grand_total": order.grand_total,
        })
    return result


@router.post("/{delivery_id}/status")
def update_delivery_status(
    delivery_id: int,
    payload: OrderStatusUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(["delivery"])),
):
    delivery = db.query(Delivery).filter(Delivery.id == delivery_id).first()
    if not delivery:
        raise HTTPException(status_code=404, detail="Delivery नहीं मिली।")

    dp = db.query(DeliveryPartner).filter(DeliveryPartner.user_id == user.id).first()
    if not dp or delivery.delivery_partner_id != dp.id:
        raise HTTPException(status_code=403, detail="यह delivery आपकी नहीं है।")

    try:
        new_status = DeliveryStatus(payload.status)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid delivery status.")

    if not is_delivery_transition_allowed(delivery.status, new_status):
        raise HTTPException(
            status_code=400,
            detail=f"Delivery अभी '{delivery.status.value}' status में है, '{new_status.value}' पर सीधे नहीं जा सकता।",
        )

    order = db.query(Order).filter(Order.id == delivery.order_id).first()

    # Keep the order's own state machine honest too — mirroring should
    # never silently push the order into an invalid jump.
    mapped = {
        DeliveryStatus.picked_up: OrderStatus.picked_up,
        DeliveryStatus.out_for_delivery: OrderStatus.out_for_delivery,
        DeliveryStatus.delivered: OrderStatus.delivered,
    }.get(new_status)
    if order and mapped and not is_order_transition_allowed(order.status, mapped):
        raise HTTPException(
            status_code=400,
            detail=f"Order अभी '{order.status.value}' status में है, delivery status update नहीं हो सकता।",
        )

    delivery.status = new_status
    now = datetime.utcnow()
    if new_status == DeliveryStatus.picked_up:
        delivery.picked_up_at = now
    elif new_status == DeliveryStatus.delivered:
        delivery.delivered_at = now

    db.add(DeliveryStatusHistory(delivery_id=delivery.id, status=new_status.value, changed_by_user_id=user.id))

    # Mirror the delivery status onto the parent order so customer/seller
    # tracking screens stay in sync (single source of truth for the UI).
    if order and mapped:
        order.status = mapped
        db.add(OrderStatusHistory(order_id=order.id, status=mapped, changed_by_user_id=user.id))

    db.commit()
    return {"message": "Delivery status update हो गया।", "status": new_status.value}
