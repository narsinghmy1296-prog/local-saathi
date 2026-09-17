import enum
from datetime import datetime

from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum
from sqlalchemy.orm import relationship

from app.core.database import Base


class UserRole(str, enum.Enum):
    customer = "customer"
    seller = "seller"
    delivery = "delivery"
    admin = "admin"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    phone = Column(String(15), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), nullable=False, index=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    seller_profile = relationship("Seller", back_populates="user", uselist=False)
    delivery_profile = relationship("DeliveryPartner", back_populates="user", uselist=False)
    addresses = relationship("Address", back_populates="customer")
