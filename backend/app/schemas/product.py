from pydantic import BaseModel, Field


class CategoryCreate(BaseModel):
    name_hi: str = Field(..., min_length=1, max_length=100)
    name_en: str = Field(..., min_length=1, max_length=100)
    icon_url: str | None = None
    sort_order: int = 0


class CategoryOut(BaseModel):
    id: int
    name_hi: str
    name_en: str
    icon_url: str | None
    sort_order: int
    is_active: bool

    class Config:
        from_attributes = True


class ProductCreate(BaseModel):
    # category_id = None  →  product is filed under "Other" (requirement #14)
    category_id: int | None = None
    name: str = Field(..., min_length=1, max_length=150)
    description: str | None = None
    price: float = Field(..., gt=0, description="Must be greater than 0")
    unit: str = Field(..., min_length=1, max_length=30)
    available_qty: float = Field(0, ge=0)
    min_order_qty: float = Field(1, gt=0)
    image_url: str | None = None
    keywords: list[str] = []


class ProductUpdate(BaseModel):
    """
    All fields optional — seller/admin sends only what changes. Price and
    category changes are audit-logged by the router (requirement #24).
    """
    category_id: int | None = None
    name: str | None = Field(None, min_length=1, max_length=150)
    description: str | None = None
    price: float | None = Field(None, gt=0)
    unit: str | None = Field(None, min_length=1, max_length=30)
    min_order_qty: float | None = Field(None, gt=0)
    image_url: str | None = None
    is_active: bool | None = None


class ProductStockUpdate(BaseModel):
    available_qty: float = Field(..., ge=0)
    stock_status: str


class ProductOut(BaseModel):
    id: int
    seller_id: int
    category_id: int | None
    is_other: bool
    name: str
    description: str | None
    price: float
    unit: str
    available_qty: float
    min_order_qty: float
    stock_status: str
    image_url: str | None
    is_active: bool

    class Config:
        from_attributes = True
