from pydantic import BaseModel


class SellerOut(BaseModel):
    """
    Flattened seller + owning-user view for the Admin Panel. Keeps
    Seller.id (the seller-profile id used everywhere else, e.g.
    products.seller_id) clearly distinct from user_id (the login/User
    row id) — the Master Prompt explicitly warns against confusing the
    two, so both are always present and separately named here.
    """
    id: int
    user_id: int
    shop_name: str
    owner_name: str
    area: str
    upi_id: str | None
    is_approved: bool
    phone: str
    is_account_active: bool
    product_count: int

    class Config:
        from_attributes = True


class DeliveryPartnerOut(BaseModel):
    id: int
    user_id: int
    name: str
    phone: str
    vehicle_type: str | None
    area: str
    is_approved: bool
    is_available: bool
    is_account_active: bool

    class Config:
        from_attributes = True
