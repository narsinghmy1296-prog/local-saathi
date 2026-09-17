import enum
from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, Enum, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class StockStatus(str, enum.Enum):
    in_stock = "in_stock"
    low_stock = "low_stock"
    out_of_stock = "out_of_stock"


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    seller_id = Column(Integer, ForeignKey("sellers.id"), nullable=False)

    # nullable category_id = product is currently "Other / Uncategorized"
    # (requirement #14) — admin later moves it into a real category via
    # /products/{id}/move-category, which just sets this FK — original
    # product row is never deleted (requirement #20).
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True, index=True)
    is_other = Column(Boolean, default=False)  # True until admin moves it to a category

    name = Column(String(150), nullable=False, index=True)
    description = Column(Text, nullable=True)
    price = Column(Float, nullable=False)
    unit = Column(String(30), nullable=False)  # piece/kg/gram/litre/packet/etc (free text, admin-configurable list on client)
    available_qty = Column(Float, default=0)
    min_order_qty = Column(Float, default=1)
    stock_status = Column(Enum(StockStatus), default=StockStatus.in_stock, index=True)
    image_url = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)

    seller = relationship("Seller", back_populates="products")
    category = relationship("Category", back_populates="products")
    keywords = relationship("ProductKeyword", back_populates="product", cascade="all, delete-orphan")


class ProductKeyword(Base):
    """
    Extra search terms a seller enters (requirement #14/#15) — e.g. for
    चप्पल: 'फुटवियर', 'footwear', 'slipper', 'sandal'. Indexed so the
    smart search can match on any of them.
    """
    __tablename__ = "product_keywords"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    keyword = Column(String(100), nullable=False, index=True)

    product = relationship("Product", back_populates="keywords")
