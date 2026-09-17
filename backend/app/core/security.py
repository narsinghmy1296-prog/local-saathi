from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.models.user import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class Bearer401(HTTPBearer):
    """
    FIX (found via real pytest run): FastAPI's stock HTTPBearer raises a
    403 "Not authenticated" when the Authorization header is missing
    entirely — only a malformed/invalid token reaches our own 401 logic
    below. This subclass converts that specific 403 into a proper 401
    with a WWW-Authenticate header; the Swagger "Authorize" box still
    works exactly the same.
    """

    async def __call__(self, request: Request) -> Optional[HTTPAuthorizationCredentials]:
        try:
            return await super().__call__(request)
        except HTTPException as exc:
            if exc.status_code == status.HTTP_403_FORBIDDEN:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Login जरूरी है।",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            raise


http_bearer = Bearer401(auto_error=True)


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(http_bearer),
    db: Session = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Login फिर से करें (session expired/invalid)।",
        headers={"WWW-Authenticate": "Bearer"},
    )
    token = credentials.credentials
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except (JWTError, ValueError, TypeError):
        raise credentials_exception

    try:
        user = db.query(User).filter(User.id == int(user_id)).first()
    except (ValueError, TypeError):
        raise credentials_exception
    if user is None or not user.is_active:
        raise credentials_exception
    return user


def require_role(allowed_roles: List[str]):
    """Dependency factory — use as Depends(require_role(["admin"]))."""

    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role.value not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="इस action की अनुमति आपको नहीं है।",
            )
        return current_user

    return role_checker
