from pydantic import BaseModel, Field
from app.models.user import UserRole


class UserRegister(BaseModel):
    phone: str = Field(..., pattern=r"^[6-9]\d{9}$", description="10-digit Indian mobile number")
    name: str = Field(..., min_length=1, max_length=100)
    password: str = Field(..., min_length=6)
    role: UserRole

    # role-specific optional fields
    shop_name: str | None = Field(None, max_length=150)
    owner_name: str | None = Field(None, max_length=100)
    area: str | None = Field(None, max_length=150)
    upi_id: str | None = Field(None, max_length=100)
    vehicle_type: str | None = Field(None, max_length=50)


class UserLogin(BaseModel):
    phone: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: UserRole


class UserOut(BaseModel):
    id: int
    phone: str
    name: str
    role: UserRole
    is_active: bool

    class Config:
        from_attributes = True
