import enum
from datetime import datetime
from sqlalchemy import Column, Integer, Float, String, ForeignKey, Enum, DateTime
from sqlalchemy.orm import relationship

from app.core.database import Base


class OrderStatus(str, enum.Enum):
    placed = "placed"
    accepted = "accepted"
    preparing = "preparing"
    delivery_assigned = "delivery_assigned"
    picked_up = "picked_up"
    out_for_delivery = "out_for_delivery"
    delivered = "delivered"
    cancelled = "cancelled"
    rejected = "rejected"


class PaymentMethod(str, enum.Enum):
    upi = "upi"
    cod = "cod"


class PaymentStatus(str, enum.Enum):
    pending = "pending"
    initiated = "initiated"
    paid = "paid"
    cash_received = "cash_received"
    failed = "failed"
    unverified = "unverified"


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    address_id = Column(Integer, ForeignKey("addresses.id"), nullable=False)
    seller_id = Column(Integer, ForeignKey("sellers.id"), nullable=False)
    delivery_partner_id = Column(Integer, ForeignKey("delivery_partners.id"), nullable=True)

    status = Column(Enum(OrderStatus), default=OrderStatus.placed, index=True)
    subtotal = Column(Float, nullable=False)
    delivery_charge = Column(Float, default=0)
    discount = Column(Float, default=0)
    grand_total = Column(Float, nullable=False)

    payment_method = Column(Enum(PaymentMethod), nullable=False)
    payment_status = Column(Enum(PaymentStatus), default=PaymentStatus.pending, index=True)

    created_at = Column(DateTime, default=datetime.utcnow)

    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    status_history = relationship("OrderStatusHistory", back_populates="order", cascade="all, delete-orphan")

    # These were referenced (order.customer, order.seller, order.address)
    # in Phase 6 code (delivery.py, invoice endpoint) but never actually
    # declared — that would have raised AttributeError at runtime the
    # first time those endpoints ran. Fixed here as part of Phase 6.5
    # hardening; no DB schema change, just exposing the existing FKs.
    customer = relationship("User", foreign_keys=[customer_id])
    seller = relationship("Seller", foreign_keys=[seller_id])
    address = relationship("Address", foreign_keys=[address_id])
    delivery_partner = relationship("DeliveryPartner", foreign_keys=[delivery_partner_id])


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Float, nullable=False)
    unit_price = Column(Float, nullable=False)
    amount = Column(Float, nullable=False)

    order = relationship("Order", back_populates="items")
    product = relationship("Product")


class OrderStatusHistory(Base):
    __tablename__ = "order_status_history"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    status = Column(Enum(OrderStatus), nullable=False)
    changed_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)

    order = relationship("Order", back_populates="status_history")
