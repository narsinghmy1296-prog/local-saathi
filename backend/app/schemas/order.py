from pydantic import BaseModel, Field, field_validator


class CartItemAdd(BaseModel):
    product_id: int
    quantity: float = Field(1, gt=0)


class CartItemUpdate(BaseModel):
    """Separate from CartItemAdd: 0 is allowed here (means 'remove item')."""
    product_id: int
    quantity: float = Field(..., ge=0)


class AddressCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    mobile: str = Field(..., pattern=r"^[6-9]\d{9}$", description="10-digit Indian mobile number")
    village_town: str = Field(..., min_length=1, max_length=150)
    house: str | None = None
    landmark: str | None = None
    pincode: str = Field(..., pattern=r"^\d{6}$", description="6-digit PIN code")
    lat: float | None = None
    lng: float | None = None
    is_default: bool = False


class AddressOut(BaseModel):
    """
    FIX (Flutter integration audit): the addresses router was returning
    raw SQLAlchemy ORM objects with no response_model. FastAPI's
    jsonable_encoder falls back to vars(obj) for unrecognized objects,
    which pulls in SQLAlchemy's internal `_sa_instance_state` — that is
    not JSON-serializable, so every call to GET/POST/PUT /addresses would
    have thrown a 500 error. This schema makes the response explicit and
    matches exactly what the Customer app's Address.fromJson expects.
    """
    id: int
    name: str
    mobile: str
    village_town: str
    house: str | None
    landmark: str | None
    pincode: str
    lat: float | None
    lng: float | None
    is_default: bool

    class Config:
        from_attributes = True


class CheckoutRequest(BaseModel):
    address_id: int
    payment_method: str  # "upi" or "cod"

    @field_validator("payment_method")
    @classmethod
    def validate_payment_method(cls, v: str) -> str:
        if v not in ("upi", "cod"):
            raise ValueError("payment_method must be 'upi' or 'cod'")
        return v


class OrderStatusUpdate(BaseModel):
    status: str
    # Optional — only used by admin for manual delivery-partner assignment
    # (requirement #8). Ignored for every other transition/role.
    delivery_partner_id: int | None = None


class PaymentStatusUpdate(BaseModel):
    new_status: str  # e.g. "paid", "cash_received"


class DeliveryZoneCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=150)
    pincode: str = Field(..., pattern=r"^\d{6}$", description="6-digit PIN code")
