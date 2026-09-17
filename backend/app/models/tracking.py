import enum
from datetime import datetime
from sqlalchemy import Column, Integer, Float, String, ForeignKey, Enum, DateTime, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class PaymentAuditLog(Base):
    """
    Every manual payment-status change is recorded here — mandatory per
    requirement #34: user id, order id, time, method, old/new status.
    """
    __tablename__ = "payment_audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    payment_method = Column(String(20), nullable=False)
    old_status = Column(String(20), nullable=False)
    new_status = Column(String(20), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)


class DeliveryStatus(str, enum.Enum):
    assigned = "assigned"
    picked_up = "picked_up"
    out_for_delivery = "out_for_delivery"
    delivered = "delivered"


class Delivery(Base):
    __tablename__ = "deliveries"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), unique=True, nullable=False)
    delivery_partner_id = Column(Integer, ForeignKey("delivery_partners.id"), nullable=False)
    status = Column(Enum(DeliveryStatus), default=DeliveryStatus.assigned)
    assigned_at = Column(DateTime, default=datetime.utcnow)
    picked_up_at = Column(DateTime, nullable=True)
    delivered_at = Column(DateTime, nullable=True)


class DeliveryStatusHistory(Base):
    __tablename__ = "delivery_status_history"

    id = Column(Integer, primary_key=True, index=True)
    delivery_id = Column(Integer, ForeignKey("deliveries.id"), nullable=False)
    status = Column(String(30), nullable=False)
    changed_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)


class Invoice(Base):
    __tablename__ = "invoices"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), unique=True, nullable=False)
    invoice_number = Column(String(50), unique=True, nullable=False)
    generated_at = Column(DateTime, default=datetime.utcnow)


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(150), nullable=False)
    body = Column(Text, nullable=True)
    is_read = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)


class AdminAction(Base):
    """
    Generic audit trail (requirement #54). Despite the table/column name
    (kept as-is from Phase 6 to avoid an unnecessary migration), this is
    used for ANY privileged actor's audited change — admin actions
    (category/seller/delivery-partner approval, move-category) as well as
    a seller editing/deactivating their own product. `admin_user_id` is
    really "actor_user_id"; every write always carries a real user id.
    """
    __tablename__ = "admin_actions"

    id = Column(Integer, primary_key=True, index=True)
    admin_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action = Column(String(100), nullable=False)
    entity_type = Column(String(50), nullable=False)
    entity_id = Column(Integer, nullable=False)
    old_value = Column(Text, nullable=True)
    new_value = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
