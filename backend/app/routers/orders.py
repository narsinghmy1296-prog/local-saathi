import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_role, get_current_user
from app.core.state_machine import (
    ORDER_TRANSITION_ROLES, is_order_transition_allowed, is_payment_transition_allowed,
)
from app.models.user import User
from app.models.cart import Cart
from app.models.address import Address, DeliveryZone
from app.models.product import Product
from app.models.seller import Seller, DeliveryPartner
from app.models.order import Order, OrderItem, OrderStatusHistory, OrderStatus, PaymentMethod, PaymentStatus
from app.models.tracking import Delivery, DeliveryStatus, PaymentAuditLog, Invoice
from app.schemas.order import CheckoutRequest, OrderStatusUpdate, PaymentStatusUpdate

router = APIRouter(prefix="/api/v1/orders", tags=["orders"])

# Delivery charge slabs (requirement #36) — simple flat default for MVP,
# admin-configurable version can move this into a DB table later.
FLAT_DELIVERY_CHARGE = 20.0


def _lock_product(db: Session, product_id: int) -> Product | None:
    """
    Re-fetch a product fresh from the DB (never trust an already-loaded
    ORM object or anything the client sent) immediately before using its
    price/stock for an order (requirement #10). On a database that
    supports row locking (Postgres in production) this also takes a
    row-level lock so two simultaneous checkouts can't oversell the same
    stock; SQLite (dev) has no real row locking, so the lock is skipped
    there — documented limitation, see README.
    """
    query = db.query(Product).filter(Product.id == product_id)
    if db.bind.dialect.name != "sqlite":
        query = query.with_for_update()
    return query.first()


def _get_seller_profile(db: Session, user: User) -> Seller | None:
    return db.query(Seller).filter(Seller.user_id == user.id).first()


def _get_delivery_profile(db: Session, user: User) -> DeliveryPartner | None:
    return db.query(DeliveryPartner).filter(DeliveryPartner.user_id == user.id).first()


def _assert_order_visible(db: Session, order: Order, user: User) -> None:
    """
    Ownership check shared by read endpoints (detail/invoice): customer
    sees only their own order, seller only orders on their shop, delivery
    partner only orders assigned to them, admin sees everything.
    """
    role = user.role.value
    if role == "admin":
        return
    if role == "customer" and order.customer_id == user.id:
        return
    if role == "seller":
        seller = _get_seller_profile(db, user)
        if seller and order.seller_id == seller.id:
            return
    if role == "delivery":
        dp = _get_delivery_profile(db, user)
        if dp and order.delivery_partner_id == dp.id:
            return
    raise HTTPException(status_code=403, detail="यह order आपका नहीं है।")


@router.post("")
def checkout(
    payload: CheckoutRequest,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(["customer"])),
):
    cart = db.query(Cart).filter(Cart.customer_id == user.id).first()
    if not cart or not cart.items:
        raise HTTPException(status_code=400, detail="Cart खाली है।")

    address = db.query(Address).filter(Address.id == payload.address_id, Address.customer_id == user.id).first()
    if not address:
        raise HTTPException(status_code=404, detail="Address नहीं मिला।")

    # Re-validate the delivery zone at checkout time too (requirement #9)
    # — an address could have been valid when saved but the zone since
    # deactivated by admin. Never rely on the earlier check alone.
    zone = db.query(DeliveryZone).filter(
        DeliveryZone.pincode == address.pincode, DeliveryZone.is_active == True  # noqa: E712
    ).first()
    if not zone:
        raise HTTPException(status_code=400, detail="अभी हम इस area में delivery नहीं करते हैं।")

    # MVP: one seller per order (all cart items must belong to the same
    # seller) — keeps the accept/prepare/pickup workflow simple.
    seller_ids = {item.product.seller_id for item in cart.items}
    if len(seller_ids) > 1:
        raise HTTPException(status_code=400, detail="एक बार में एक ही दुकान से order करें।")
    seller_id = seller_ids.pop()

    # requirement #10: re-verify price/stock/active-status straight from
    # the DB — never trust anything cached on the cart item or sent by the
    # client. requirement #22: this whole block commits atomically at the
    # end; if anything raises, nothing is written (checkout, stock
    # deduction and order creation happen in one transaction).
    subtotal = 0.0
    order_items_data = []
    try:
        for item in cart.items:
            product = _lock_product(db, item.product_id)
            if not product or not product.is_active:
                raise HTTPException(status_code=400, detail="एक product अब उपलब्ध नहीं है।")
            if product.stock_status.value == "out_of_stock":
                raise HTTPException(status_code=400, detail=f"{product.name} अभी उपलब्ध नहीं है।")
            if item.quantity < product.min_order_qty:
                raise HTTPException(status_code=400, detail=f"{product.name} का न्यूनतम order {product.min_order_qty} है।")
            if item.quantity > product.available_qty:
                raise HTTPException(status_code=400, detail=f"{product.name} इतनी quantity में उपलब्ध नहीं है।")

            amount = item.quantity * product.price  # DB price, never client price
            subtotal += amount
            order_items_data.append((product, item.quantity, amount))

        grand_total = subtotal + FLAT_DELIVERY_CHARGE

        order = Order(
            customer_id=user.id,
            address_id=address.id,
            seller_id=seller_id,
            status=OrderStatus.placed,
            subtotal=round(subtotal, 2),
            delivery_charge=FLAT_DELIVERY_CHARGE,
            discount=0,
            grand_total=round(grand_total, 2),
            payment_method=PaymentMethod(payload.payment_method),
            payment_status=PaymentStatus.pending,
        )
        db.add(order)
        db.flush()

        for product, qty, amount in order_items_data:
            db.add(OrderItem(order_id=order.id, product_id=product.id, quantity=qty, unit_price=product.price, amount=round(amount, 2)))
            # Deduct stock now that the order is confirmed (requirement
            # #22 — avoid overselling).
            product.available_qty -= qty
            if product.available_qty <= 0:
                product.available_qty = 0
                product.stock_status = "out_of_stock"
            elif product.available_qty <= (product.min_order_qty * 2):
                product.stock_status = "low_stock"

        db.add(OrderStatusHistory(order_id=order.id, status=OrderStatus.placed, changed_by_user_id=user.id))

        for item in list(cart.items):
            db.delete(item)

        db.commit()
    except HTTPException:
        db.rollback()
        raise
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Order place करने में समस्या हुई, दोबारा कोशिश करें।")

    db.refresh(order)
    return {"order_id": order.id, "status": order.status.value, "grand_total": order.grand_total}


@router.get("")
def my_orders(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    if user.role.value == "customer":
        orders = db.query(Order).filter(Order.customer_id == user.id).all()
    elif user.role.value == "seller":
        seller = _get_seller_profile(db, user)
        orders = db.query(Order).filter(Order.seller_id == seller.id).all() if seller else []
    elif user.role.value == "delivery":
        dp = _get_delivery_profile(db, user)
        orders = db.query(Order).filter(Order.delivery_partner_id == dp.id).all() if dp else []
    else:  # admin
        orders = db.query(Order).all()

    return [
        {
            "id": o.id, "status": o.status.value, "payment_method": o.payment_method.value,
            "payment_status": o.payment_status.value, "grand_total": o.grand_total,
            "created_at": o.created_at.isoformat(),
            # FIX (Flutter integration audit): added so the "My Orders" list
            # can show an item count without a second network call — this
            # is a pure addition, existing consumers ignore unknown fields.
            "item_count": len(o.items),
        }
        for o in orders
    ]


@router.get("/{order_id}")
def order_detail(order_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order नहीं मिला।")
    _assert_order_visible(db, order, user)

    return {
        "id": order.id,
        "status": order.status.value,
        "payment_method": order.payment_method.value,
        "payment_status": order.payment_status.value,
        "subtotal": order.subtotal,
        "delivery_charge": order.delivery_charge,
        "discount": order.discount,
        "grand_total": order.grand_total,
        "items": [
            {"product_id": i.product_id, "name": i.product.name, "quantity": i.quantity, "unit_price": i.unit_price, "amount": i.amount}
            for i in order.items
        ],
        "status_history": [
            {"status": h.status.value, "timestamp": h.timestamp.isoformat()} for h in order.status_history
        ],
    }


@router.post("/{order_id}/status")
def update_order_status(
    order_id: int,
    payload: OrderStatusUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order नहीं मिला।")

    try:
        new_status = OrderStatus(payload.status)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid status.")

    role = user.role.value
    allowed_roles = ORDER_TRANSITION_ROLES.get(new_status, [])
    if role not in allowed_roles:
        raise HTTPException(status_code=403, detail="इस status change की अनुमति आपको नहीं है।")

    # Strict state machine — no skipping ahead (requirement #1).
    if not is_order_transition_allowed(order.status, new_status):
        raise HTTPException(
            status_code=400,
            detail=f"Order अभी '{order.status.value}' status में है, '{new_status.value}' पर सीधे नहीं जा सकता।",
        )

    # Ownership — a role check alone is not enough (requirement #2/#3).
    if role == "seller":
        seller = _get_seller_profile(db, user)
        if not seller or order.seller_id != seller.id:
            raise HTTPException(status_code=403, detail="यह order आपकी shop का नहीं है।")
    elif role == "delivery":
        dp = _get_delivery_profile(db, user)
        if not dp or order.delivery_partner_id != dp.id:
            raise HTTPException(status_code=403, detail="यह order आपको assign नहीं है।")
    elif role == "customer":
        if order.customer_id != user.id:
            raise HTTPException(status_code=403, detail="यह order आपका नहीं है।")

    # When seller (or admin) assigns for delivery, create the Delivery row.
    if new_status == OrderStatus.delivery_assigned:
        chosen_dp = None
        if role == "admin" and payload.delivery_partner_id:
            chosen_dp = db.query(DeliveryPartner).filter(
                DeliveryPartner.id == payload.delivery_partner_id,
                DeliveryPartner.is_approved == True,  # noqa: E712
            ).first()
            if not chosen_dp:
                raise HTTPException(status_code=400, detail="चुना गया delivery partner उपलब्ध नहीं है।")
        else:
            # requirement #8 — prefer a partner in the same area as the
            # seller (simple zone match) before falling back to "any
            # available approved partner".
            seller = db.query(Seller).filter(Seller.id == order.seller_id).first()
            base_q = db.query(DeliveryPartner).filter(
                DeliveryPartner.is_approved == True, DeliveryPartner.is_available == True  # noqa: E712
            )
            if seller:
                chosen_dp = base_q.filter(DeliveryPartner.area == seller.area).first()
            if not chosen_dp:
                chosen_dp = base_q.first()
        if not chosen_dp:
            raise HTTPException(status_code=400, detail="अभी कोई delivery partner उपलब्ध नहीं है।")

        db.add(Delivery(order_id=order.id, delivery_partner_id=chosen_dp.id, status=DeliveryStatus.assigned))
        order.delivery_partner_id = chosen_dp.id

    order.status = new_status
    db.add(OrderStatusHistory(order_id=order.id, status=new_status, changed_by_user_id=user.id))
    db.commit()
    return {"message": "Order status update हो गया।", "status": new_status.value}


@router.post("/{order_id}/cancel")
def cancel_order(order_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order नहीं मिला।")

    role = user.role.value
    if role == "customer" and order.customer_id != user.id:
        raise HTTPException(status_code=403, detail="यह order आपका नहीं है।")
    if role == "seller":
        seller = _get_seller_profile(db, user)
        if not seller or order.seller_id != seller.id:
            raise HTTPException(status_code=403, detail="यह order आपकी shop का नहीं है।")
    if role == "delivery":
        raise HTTPException(status_code=403, detail="Delivery partner order cancel नहीं कर सकता।")

    if not is_order_transition_allowed(order.status, OrderStatus.cancelled):
        raise HTTPException(status_code=400, detail="अब यह order cancel नहीं हो सकता।")

    # Restore stock for a cancelled order — it was deducted at checkout.
    for item in order.items:
        product = db.query(Product).filter(Product.id == item.product_id).first()
        if product:
            product.available_qty += item.quantity
            if product.available_qty > 0 and product.stock_status.value == "out_of_stock":
                product.stock_status = "in_stock"

    order.status = OrderStatus.cancelled
    db.add(OrderStatusHistory(order_id=order.id, status=OrderStatus.cancelled, changed_by_user_id=user.id))
    db.commit()
    return {"message": "Order cancel हो गया।"}


@router.post("/{order_id}/payment/mark-received")
def mark_payment_received(
    order_id: int,
    payload: PaymentStatusUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """
    Manual payment-status confirmation (requirement #33/#34/#58) — no
    payment gateway exists, so a human confirms. Ownership + state-machine
    enforced (requirement #4/#5); every change is written to
    payment_audit_logs regardless of outcome.
    """
    role = user.role.value
    if role not in ("seller", "delivery", "admin"):
        raise HTTPException(status_code=403, detail="इस action की अनुमति आपको नहीं है।")

    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order नहीं मिला।")

    # Ownership — a seller/delivery partner may only touch payment on
    # their own order (requirement #4).
    if role == "seller":
        seller = _get_seller_profile(db, user)
        if not seller or order.seller_id != seller.id:
            raise HTTPException(status_code=403, detail="यह order आपकी shop का नहीं है।")
    elif role == "delivery":
        dp = _get_delivery_profile(db, user)
        if not dp or order.delivery_partner_id != dp.id:
            raise HTTPException(status_code=403, detail="यह order आपको assign नहीं है।")

    try:
        new_status = PaymentStatus(payload.new_status)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payment status.")

    old_status = order.payment_status
    if not is_payment_transition_allowed(old_status, new_status, role):
        raise HTTPException(
            status_code=400,
            detail=f"Payment status '{old_status.value}' से '{new_status.value}' में सीधे नहीं बदल सकते।",
        )

    # Every attempted change is logged, including admin overrides.
    db.add(PaymentAuditLog(
        order_id=order.id, user_id=user.id,
        payment_method=order.payment_method.value,
        old_status=old_status.value, new_status=new_status.value,
    ))
    order.payment_status = new_status
    db.commit()
    return {"message": "Payment status update हो गया।", "payment_status": new_status.value}


@router.get("/{order_id}/invoice")
def get_invoice(order_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order नहीं मिला।")
    _assert_order_visible(db, order, user)

    invoice = db.query(Invoice).filter(Invoice.order_id == order.id).first()
    if not invoice:
        invoice = Invoice(order_id=order.id, invoice_number=f"LS-{order.id}-{uuid.uuid4().hex[:6].upper()}")
        db.add(invoice)
        db.commit()
        db.refresh(invoice)

    return {
        "invoice_number": invoice.invoice_number,
        "generated_at": invoice.generated_at.isoformat(),
        "order_id": order.id,
        "customer": order.customer.name if order.customer else None,
        "seller": order.seller.shop_name if order.seller else None,
        "items": [
            {"name": i.product.name, "quantity": i.quantity, "unit_price": i.unit_price, "amount": i.amount}
            for i in order.items
        ],
        "subtotal": order.subtotal,
        "delivery_charge": order.delivery_charge,
        "discount": order.discount,
        "grand_total": order.grand_total,
        "payment_status": order.payment_status.value,
    }
