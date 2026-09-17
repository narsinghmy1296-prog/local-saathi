"""
Centralized state machines for Order status and Payment status.

Keeping the enum *values* unchanged from Phase 6 (placed/accepted/preparing/
delivery_assigned/picked_up/out_for_delivery/delivered/cancelled/rejected)
— renaming them to PENDING/READY_FOR_PICKUP/ASSIGNED etc. would break the
already-working API contract for no functional gain. What was missing was
strict *transition* enforcement, which is what this module adds.

Linear happy path (matches the Ultra Master Prompt's flow 1:1, just with
the same names already in use):

    placed -> accepted -> preparing -> delivery_assigned -> picked_up
           -> out_for_delivery -> delivered

Cancellation/rejection are only allowed from early states — once an order
is out for delivery it can no longer be cancelled or jumped anywhere.
"""
from app.models.order import OrderStatus, PaymentStatus

# ---- Order status state machine ------------------------------------------

ORDER_ALLOWED_TRANSITIONS: dict[OrderStatus, set[OrderStatus]] = {
    OrderStatus.placed: {OrderStatus.accepted, OrderStatus.rejected, OrderStatus.cancelled},
    OrderStatus.accepted: {OrderStatus.preparing, OrderStatus.cancelled},
    OrderStatus.preparing: {OrderStatus.delivery_assigned, OrderStatus.cancelled},
    OrderStatus.delivery_assigned: {OrderStatus.picked_up, OrderStatus.cancelled},
    OrderStatus.picked_up: {OrderStatus.out_for_delivery},
    OrderStatus.out_for_delivery: {OrderStatus.delivered},
    OrderStatus.delivered: set(),
    OrderStatus.cancelled: set(),
    OrderStatus.rejected: set(),
}

# Which role(s) may push an order INTO each status. Ownership (does this
# seller/delivery-partner/customer actually own this order?) is checked
# separately in the router — this only says "the role is the right kind
# of actor for this status in general".
ORDER_TRANSITION_ROLES: dict[OrderStatus, list[str]] = {
    OrderStatus.accepted: ["seller"],
    OrderStatus.preparing: ["seller"],
    OrderStatus.delivery_assigned: ["seller", "admin"],
    OrderStatus.picked_up: ["delivery"],
    OrderStatus.out_for_delivery: ["delivery"],
    OrderStatus.delivered: ["delivery"],
    OrderStatus.rejected: ["seller"],
    OrderStatus.cancelled: ["customer", "seller", "admin"],
}


def is_order_transition_allowed(current: OrderStatus, target: OrderStatus) -> bool:
    return target in ORDER_ALLOWED_TRANSITIONS.get(current, set())


# ---- Payment status state machine -----------------------------------------

PAYMENT_ALLOWED_TRANSITIONS: dict[PaymentStatus, set[PaymentStatus]] = {
    PaymentStatus.pending: {
        PaymentStatus.initiated, PaymentStatus.cash_received,
        PaymentStatus.unverified, PaymentStatus.failed,
    },
    PaymentStatus.initiated: {PaymentStatus.paid, PaymentStatus.failed, PaymentStatus.unverified},
    PaymentStatus.cash_received: {PaymentStatus.paid},
    PaymentStatus.unverified: {PaymentStatus.paid, PaymentStatus.cash_received, PaymentStatus.failed},
    PaymentStatus.failed: {PaymentStatus.pending, PaymentStatus.initiated},
    PaymentStatus.paid: set(),  # terminal — only admin override (see below) can move off this
}


def is_payment_transition_allowed(current: PaymentStatus, target: PaymentStatus, role: str) -> bool:
    """
    Normal actors (seller/delivery) may only make moves in the allowed-map.
    Admin may override any transition (e.g. correcting a mistaken PAID),
    but the override is still fully audit-logged by the caller — this
    function only decides whether to require that extra privilege.
    """
    if target in PAYMENT_ALLOWED_TRANSITIONS.get(current, set()):
        return True
    return role == "admin"


# ---- Delivery status state machine ----------------------------------------

from app.models.tracking import DeliveryStatus  # noqa: E402

DELIVERY_ALLOWED_TRANSITIONS: dict[DeliveryStatus, set[DeliveryStatus]] = {
    DeliveryStatus.assigned: {DeliveryStatus.picked_up},
    DeliveryStatus.picked_up: {DeliveryStatus.out_for_delivery},
    DeliveryStatus.out_for_delivery: {DeliveryStatus.delivered},
    DeliveryStatus.delivered: set(),
}


def is_delivery_transition_allowed(current: DeliveryStatus, target: DeliveryStatus) -> bool:
    return target in DELIVERY_ALLOWED_TRANSITIONS.get(current, set())
