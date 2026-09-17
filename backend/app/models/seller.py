from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship

from app.core.database import Base


class Seller(Base):
    __tablename__ = "sellers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    shop_name = Column(String(150), nullable=False)
    owner_name = Column(String(100), nullable=False)
    area = Column(String(150), nullable=False, index=True)
    upi_id = Column(String(100), nullable=True)
    is_approved = Column(Boolean, default=False)

    user = relationship("User", back_populates="seller_profile")
    products = relationship("Product", back_populates="seller")


class DeliveryPartner(Base):
    __tablename__ = "delivery_partners"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    vehicle_type = Column(String(50), nullable=True)
    area = Column(String(150), nullable=False, index=True)
    is_approved = Column(Boolean, default=False)
    is_available = Column(Boolean, default=True)

    user = relationship("User", back_populates="delivery_profile")
