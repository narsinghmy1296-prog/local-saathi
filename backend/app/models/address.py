from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey
from sqlalchemy.orm import relationship

from app.core.database import Base


class Address(Base):
    __tablename__ = "addresses"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    mobile = Column(String(15), nullable=False)
    village_town = Column(String(150), nullable=False)
    house = Column(String(150), nullable=True)
    landmark = Column(String(150), nullable=True)
    pincode = Column(String(10), nullable=False, index=True)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    is_default = Column(Boolean, default=False)

    customer = relationship("User", back_populates="addresses")


class DeliveryZone(Base):
    """Local delivery-area whitelist (requirement #26) — admin managed."""
    __tablename__ = "delivery_zones"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    pincode = Column(String(10), nullable=False, index=True)
    is_active = Column(Boolean, default=True)
