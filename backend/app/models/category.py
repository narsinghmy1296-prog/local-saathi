from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship

from app.core.database import Base


class Category(Base):
    """
    Fully database-driven — admin can add/edit/deactivate/reorder without
    any code change (requirement #13). No categories are hard-coded here;
    they get inserted via a seed script or the admin API.
    """
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name_hi = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=False)
    icon_url = Column(String(255), nullable=True)
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)

    products = relationship("Product", back_populates="category")
