import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

from app.core.database import Base, get_db
from app.core.security import hash_password
from app.main import app
from app.models.user import User, UserRole
from app.models.category import Category
from app.models.address import DeliveryZone

# Isolated in-memory DB per test run — never touches the real
# local_saathi.db file.
TEST_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(scope="function", autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    # Minimal seed needed by most tests: one category, one delivery zone,
    # one admin user (mirrors seed.py but scoped to the test DB).
    db.add(Category(name_hi="दूध", name_en="Milk", sort_order=1, is_active=True))
    db.add(DeliveryZone(name="Test Zone", pincode="110001", is_active=True))
    db.add(User(
        phone="9000000000", name="Test Admin", role=UserRole.admin,
        password_hash=hash_password("admin123"), is_active=True,
    ))
    db.commit()
    db.close()
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client():
    return TestClient(app)


def register_and_login(client, phone, name, role, password="password123", **extra):
    client.post("/api/v1/auth/register", json={
        "phone": phone, "name": name, "password": password, "role": role, **extra,
    })
    resp = client.post("/api/v1/auth/login", json={"phone": phone, "password": password})
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def admin_headers(client):
    resp = client.post("/api/v1/auth/login", json={"phone": "9000000000", "password": "admin123"})
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
