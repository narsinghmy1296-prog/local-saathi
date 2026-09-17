from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token, get_current_user
from app.models.user import User, UserRole
from app.models.seller import Seller, DeliveryPartner
from app.schemas.auth import UserRegister, UserLogin, Token, UserOut

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/register", response_model=UserOut)
def register(payload: UserRegister, db: Session = Depends(get_db)):
    # CRITICAL (found in hardening audit): the public registration endpoint
    # accepted role="admin" with no restriction — anyone could have made
    # themselves an admin. Admin accounts must be created out-of-band
    # (seed.py, or directly by an existing admin) — never self-service.
    if payload.role == UserRole.admin:
        raise HTTPException(status_code=403, detail="Admin account इस तरह नहीं बनाया जा सकता।")

    existing = db.query(User).filter(User.phone == payload.phone).first()
    if existing:
        raise HTTPException(status_code=400, detail="इस mobile number से पहले से account बना है।")

    user = User(
        phone=payload.phone,
        name=payload.name,
        password_hash=hash_password(payload.password),
        role=payload.role,
        is_active=True,
    )
    db.add(user)
    db.flush()  # get user.id before commit

    # Seller and delivery-partner accounts need admin approval before they
    # can act (requirement #40/#41) — is_approved defaults to False.
    if payload.role == UserRole.seller:
        if not payload.shop_name or not payload.owner_name or not payload.area:
            raise HTTPException(status_code=400, detail="Shop name, owner name aur area zaroori hai.")
        db.add(Seller(
            user_id=user.id,
            shop_name=payload.shop_name,
            owner_name=payload.owner_name,
            area=payload.area,
            upi_id=payload.upi_id,
            is_approved=False,
        ))
    elif payload.role == UserRole.delivery:
        if not payload.area:
            raise HTTPException(status_code=400, detail="Area zaroori hai.")
        db.add(DeliveryPartner(
            user_id=user.id,
            vehicle_type=payload.vehicle_type,
            area=payload.area,
            is_approved=False,
        ))

    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(payload: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone == payload.phone).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Mobile number ya password galat hai।")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account निष्क्रिय है। Admin से संपर्क करें।")

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return Token(access_token=token, role=user.role)


@router.get("/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)):
    return current_user
