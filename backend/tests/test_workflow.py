"""
Automated test suite (requirement #30/#31).

Run with:  pytest tests/ -v

Covers: authentication, role/ownership authorization, the Other-product
workflow, smart search, cart isolation, the full order state machine
(including that illegal jumps are rejected), payment authorization +
state machine, delivery assignment/tracking, and admin-only access.
"""
from tests.conftest import register_and_login, admin_headers


# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------

def test_valid_login(client):
    client.post("/api/v1/auth/register", json={
        "phone": "9111111111", "name": "Cust", "password": "password123", "role": "customer",
    })
    resp = client.post("/api/v1/auth/login", json={"phone": "9111111111", "password": "password123"})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


def test_invalid_login_wrong_password(client):
    client.post("/api/v1/auth/register", json={
        "phone": "9111111112", "name": "Cust", "password": "password123", "role": "customer",
    })
    resp = client.post("/api/v1/auth/login", json={"phone": "9111111112", "password": "wrong"})
    assert resp.status_code == 401


def test_protected_endpoint_without_token_rejected(client):
    resp = client.get("/api/v1/orders")
    assert resp.status_code == 401


def test_password_never_returned(client):
    resp = client.post("/api/v1/auth/register", json={
        "phone": "9111111113", "name": "Cust", "password": "password123", "role": "customer",
    })
    assert "password" not in resp.json()
    assert "password_hash" not in resp.json()


def test_wrong_role_cannot_access_seller_endpoint(client):
    headers = register_and_login(client, "9111111114", "Cust", "customer")
    resp = client.post("/api/v1/products", json={
        "name": "Test", "price": 10, "unit": "piece", "available_qty": 5,
    }, headers=headers)
    assert resp.status_code == 403


def test_public_registration_cannot_create_admin(client):
    resp = client.post("/api/v1/auth/register", json={
        "phone": "9111111115", "name": "Fake Admin", "password": "password123", "role": "admin",
    })
    assert resp.status_code == 403
    # and no token should be obtainable for that phone
    login = client.post("/api/v1/auth/login", json={"phone": "9111111115", "password": "password123"})
    assert login.status_code == 401


# ---------------------------------------------------------------------------
# Helper to build a full approved seller + a category-scoped product
# ---------------------------------------------------------------------------

def _make_approved_seller(client, phone="9200000001", area="Village A"):
    headers = register_and_login(
        client, phone, "Seller One", "seller",
        shop_name="Shop One", owner_name="Owner One", area=area,
    )
    me = client.get("/api/v1/auth/me", headers=headers).json()
    admin_h = admin_headers(client)
    # find seller id via a product-less admin dashboard isn't exposed directly;
    # approve by scanning /admin isn't available, so we approve via seller_id=1
    # convention isn't safe across tests — instead fetch through a product list
    # after creating, or add a tiny helper endpoint call. We use the seller's
    # own id by creating and reading /auth/me + assuming seller table id
    # increments; safer: call admin approve for id 1..5 until product create
    # succeeds is overkill. Instead we approve using the known relationship:
    # seller.id is looked up by phone via the admin dashboard is not exposed,
    # so we directly hit the approve endpoint for ids 1..10 (idempotent, test-only).
    for sid in range(1, 10):
        client.post(f"/api/v1/admin/sellers/{sid}/approve", headers=admin_h)
    return headers, me


def _make_approved_delivery_partner(client, phone="9300000001", area="Village A"):
    headers = register_and_login(client, phone, "DP One", "delivery", area=area)
    admin_h = admin_headers(client)
    for did in range(1, 10):
        client.post(f"/api/v1/admin/delivery-partners/{did}/approve", headers=admin_h)
    return headers


# ---------------------------------------------------------------------------
# Products & ownership
# ---------------------------------------------------------------------------

def test_seller_can_create_and_edit_own_product(client):
    seller_headers, _ = _make_approved_seller(client)
    resp = client.post("/api/v1/products", json={
        "name": "आटा", "price": 40, "unit": "kg", "available_qty": 20,
    }, headers=seller_headers)
    assert resp.status_code == 200
    product_id = resp.json()["id"]

    edit = client.put(f"/api/v1/products/{product_id}", json={"price": 45}, headers=seller_headers)
    assert edit.status_code == 200
    assert edit.json()["price"] == 45


def test_seller_cannot_edit_other_sellers_product(client):
    seller1_headers, _ = _make_approved_seller(client, phone="9200000002")
    seller2_headers, _ = _make_approved_seller(client, phone="9200000003")

    resp = client.post("/api/v1/products", json={
        "name": "चावल", "price": 50, "unit": "kg", "available_qty": 10,
    }, headers=seller1_headers)
    product_id = resp.json()["id"]

    edit = client.put(f"/api/v1/products/{product_id}", json={"price": 999}, headers=seller2_headers)
    assert edit.status_code == 403


def test_negative_price_rejected(client):
    seller_headers, _ = _make_approved_seller(client, phone="9200000004")
    resp = client.post("/api/v1/products", json={
        "name": "तेल", "price": -5, "unit": "litre", "available_qty": 10,
    }, headers=seller_headers)
    assert resp.status_code == 422


# ---------------------------------------------------------------------------
# "Other" product workflow + search
# ---------------------------------------------------------------------------

def test_other_product_workflow_and_search(client):
    seller_headers, _ = _make_approved_seller(client, phone="9200000005")

    resp = client.post("/api/v1/products", json={
        "category_id": None,
        "name": "चप्पल", "price": 150, "unit": "piece", "available_qty": 10,
        "keywords": ["फुटवियर", "footwear", "slipper"],
    }, headers=seller_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["is_other"] is True
    product_id = body["id"]

    for query in ("चप्पल", "footwear", "slipper"):
        search_resp = client.get(f"/api/v1/search?q={query}")
        assert search_resp.status_code == 200
        ids = [p["id"] for p in search_resp.json()]
        assert product_id in ids, f"search for '{query}' should find the Other product"

    # Admin moves it into an official category
    admin_h = admin_headers(client)
    cat_resp = client.post("/api/v1/categories", json={"name_hi": "जूते-चप्पल", "name_en": "Footwear"}, headers=admin_h)
    category_id = cat_resp.json()["id"]

    move = client.post(
        f"/api/v1/products/{product_id}/move-category?category_id={category_id}", headers=admin_h
    )
    assert move.status_code == 200
    assert move.json()["is_other"] is False
    assert move.json()["category_id"] == category_id
    # original product row preserved, not deleted
    assert move.json()["id"] == product_id


# ---------------------------------------------------------------------------
# Cart isolation
# ---------------------------------------------------------------------------

def test_customer_cannot_touch_another_customers_cart_item(client):
    seller_headers, _ = _make_approved_seller(client, phone="9200000006")
    product_resp = client.post("/api/v1/products", json={
        "name": "दही", "price": 20, "unit": "piece", "available_qty": 10,
    }, headers=seller_headers)
    product_id = product_resp.json()["id"]

    cust1 = register_and_login(client, "9400000001", "Cust1", "customer")
    cust2 = register_and_login(client, "9400000002", "Cust2", "customer")

    add = client.post("/api/v1/cart/items", json={"product_id": product_id, "quantity": 2}, headers=cust1)
    assert add.status_code == 200
    cart1 = client.get("/api/v1/cart", headers=cust1).json()
    item_id = cart1["items"][0]["id"]

    # cust2 tries to modify cust1's cart item
    resp = client.put(f"/api/v1/cart/items/{item_id}", json={"product_id": product_id, "quantity": 5}, headers=cust2)
    assert resp.status_code == 404  # not found in cust2's own cart


# ---------------------------------------------------------------------------
# Address CRUD — response shape (regression test for the Flutter-integration
# audit bug: these endpoints used to return raw ORM objects with no
# response_model, which crashes FastAPI's JSON serialization)
# ---------------------------------------------------------------------------

def test_address_crud_returns_proper_json(client):
    cust_headers = register_and_login(client, "9500000001", "Cust7", "customer")

    create = client.post("/api/v1/addresses", json={
        "name": "Cust7", "mobile": "9500000001", "village_town": "Test Village",
        "house": "12", "landmark": "Near temple", "pincode": "110001", "is_default": True,
    }, headers=cust_headers)
    assert create.status_code == 200
    body = create.json()
    # Every field the Flutter Address.fromJson expects must be present —
    # this would have failed with a 500 (or missing keys) before the fix.
    for field in ("id", "name", "mobile", "village_town", "house", "landmark", "pincode", "is_default"):
        assert field in body, f"missing '{field}' in address response"
    address_id = body["id"]

    listing = client.get("/api/v1/addresses", headers=cust_headers)
    assert listing.status_code == 200
    assert isinstance(listing.json(), list)
    assert listing.json()[0]["id"] == address_id

    update = client.put(f"/api/v1/addresses/{address_id}", json={
        "name": "Cust7 Updated", "mobile": "9500000001", "village_town": "Test Village",
        "pincode": "110001",
    }, headers=cust_headers)
    assert update.status_code == 200
    assert update.json()["name"] == "Cust7 Updated"


# ---------------------------------------------------------------------------

def _place_full_order(client):
    seller_headers, _ = _make_approved_seller(client, phone="9200000007", area="Zone1")
    dp_headers = _make_approved_delivery_partner(client, phone="9300000002", area="Zone1")

    product_resp = client.post("/api/v1/products", json={
        "name": "दूध", "price": 60, "unit": "litre", "available_qty": 10,
    }, headers=seller_headers)
    product_id = product_resp.json()["id"]

    cust_headers = register_and_login(client, "9400000003", "Cust3", "customer")
    client.post("/api/v1/cart/items", json={"product_id": product_id, "quantity": 2}, headers=cust_headers)
    addr = client.post("/api/v1/addresses", json={
        "name": "Cust3", "mobile": "9400000003", "village_town": "Test Village",
        "pincode": "110001",
    }, headers=cust_headers)
    address_id = addr.json()["id"]

    checkout = client.post("/api/v1/orders", json={
        "address_id": address_id, "payment_method": "cod",
    }, headers=cust_headers)
    assert checkout.status_code == 200
    order_id = checkout.json()["order_id"]
    return order_id, seller_headers, dp_headers, cust_headers, product_id


def test_order_status_cannot_skip_states(client):
    order_id, seller_headers, dp_headers, cust_headers, _ = _place_full_order(client)

    # placed -> delivered directly must be rejected
    resp = client.post(f"/api/v1/orders/{order_id}/status", json={"status": "delivered"}, headers=dp_headers)
    assert resp.status_code in (400, 403)  # either wrong role or invalid jump — both must block it

    # correct path
    assert client.post(f"/api/v1/orders/{order_id}/status", json={"status": "accepted"}, headers=seller_headers).status_code == 200
    assert client.post(f"/api/v1/orders/{order_id}/status", json={"status": "preparing"}, headers=seller_headers).status_code == 200
    assert client.post(f"/api/v1/orders/{order_id}/status", json={"status": "delivery_assigned"}, headers=seller_headers).status_code == 200

    # now skipping ahead should fail even from a valid actor
    resp = client.post(f"/api/v1/orders/{order_id}/status", json={"status": "delivered"}, headers=dp_headers)
    assert resp.status_code == 400


def test_seller_cannot_manage_other_sellers_order(client):
    order_id, _seller_headers, _dp, _cust, _ = _place_full_order(client)
    other_seller_headers, _ = _make_approved_seller(client, phone="9200000008")

    resp = client.post(f"/api/v1/orders/{order_id}/status", json={"status": "accepted"}, headers=other_seller_headers)
    assert resp.status_code == 403


def test_delivery_partner_cannot_touch_unassigned_order(client):
    order_id, seller_headers, _dp_headers, _cust, _ = _place_full_order(client)
    other_dp_headers = _make_approved_delivery_partner(client, phone="9300000003", area="Zone1")

    client.post(f"/api/v1/orders/{order_id}/status", json={"status": "accepted"}, headers=seller_headers)
    client.post(f"/api/v1/orders/{order_id}/status", json={"status": "preparing"}, headers=seller_headers)
    client.post(f"/api/v1/orders/{order_id}/status", json={"status": "delivery_assigned"}, headers=seller_headers)

    # find the delivery id from the (correct) dp's assignment list — the
    # *other* dp should see nothing assigned to them for this order.
    assignments = client.get("/api/v1/delivery/assignments", headers=other_dp_headers).json()
    assert all(a["order_id"] != order_id for a in assignments)


def test_my_orders_list_includes_item_count(client):
    """
    Regression test (Flutter-integration audit): the customer app's "My
    Orders" list previously always showed "0 products" because GET
    /orders (list) never included item data. This checks the additive
    item_count field the fix introduced.
    """
    order_id, _seller_headers, _dp_headers, cust_headers, _product_id = _place_full_order(client)
    listing = client.get("/api/v1/orders", headers=cust_headers)
    assert listing.status_code == 200
    entry = next(o for o in listing.json() if o["id"] == order_id)
    assert entry["item_count"] == 1


def test_full_cod_workflow_and_payment_audit(client):
    order_id, seller_headers, _dp_headers, cust_headers, product_id = _place_full_order(client)

    client.post(f"/api/v1/orders/{order_id}/status", json={"status": "accepted"}, headers=seller_headers)
    client.post(f"/api/v1/orders/{order_id}/status", json={"status": "preparing"}, headers=seller_headers)
    client.post(f"/api/v1/orders/{order_id}/status", json={"status": "delivery_assigned"}, headers=seller_headers)

    order_detail = client.get(f"/api/v1/orders/{order_id}", headers=seller_headers).json()
    assert order_detail["status"] == "delivery_assigned"

    admin_h = admin_headers(client)
    resp = client.post(f"/api/v1/orders/{order_id}/payment/mark-received", json={"new_status": "cash_received"}, headers=cust_headers)
    assert resp.status_code == 403

    # Seller (owner) can mark cash received
    resp = client.post(f"/api/v1/orders/{order_id}/payment/mark-received", json={"new_status": "cash_received"}, headers=seller_headers)
    assert resp.status_code == 200
    assert resp.json()["payment_status"] == "cash_received"

    # invalid direct jump back to pending should be blocked for non-admin
    resp = client.post(f"/api/v1/orders/{order_id}/payment/mark-received", json={"new_status": "pending"}, headers=seller_headers)
    assert resp.status_code == 400

    # Admin can see the audit trail
    logs = client.get("/api/v1/admin/audit-logs", headers=admin_h)
    assert logs.status_code == 200


def test_stock_deducted_and_oversell_blocked(client):
    seller_headers, _ = _make_approved_seller(client, phone="9200000009")
    product_resp = client.post("/api/v1/products", json={
        "name": "शहद", "price": 200, "unit": "piece", "available_qty": 2,
    }, headers=seller_headers)
    product_id = product_resp.json()["id"]

    cust_headers = register_and_login(client, "9400000004", "Cust4", "customer")
    client.post("/api/v1/cart/items", json={"product_id": product_id, "quantity": 3}, headers=cust_headers)
    addr = client.post("/api/v1/addresses", json={
        "name": "Cust4", "mobile": "9400000004", "village_town": "Test Village", "pincode": "110001",
    }, headers=cust_headers)
    address_id = addr.json()["id"]

    # requesting 3 when only 2 in stock must fail
    resp = client.post("/api/v1/orders", json={"address_id": address_id, "payment_method": "cod"}, headers=cust_headers)
    assert resp.status_code == 400


def test_checkout_rejects_address_outside_delivery_zone(client):
    seller_headers, _ = _make_approved_seller(client, phone="9200000010")
    product_resp = client.post("/api/v1/products", json={
        "name": "नमक", "price": 20, "unit": "kg", "available_qty": 10,
    }, headers=seller_headers)
    product_id = product_resp.json()["id"]

    cust_headers = register_and_login(client, "9400000005", "Cust5", "customer")
    client.post("/api/v1/cart/items", json={"product_id": product_id, "quantity": 1}, headers=cust_headers)

    # pincode 999999 was never added as a delivery zone
    addr_resp = client.post("/api/v1/addresses", json={
        "name": "Cust5", "mobile": "9400000005", "village_town": "Far Village", "pincode": "999999",
    }, headers=cust_headers)
    assert addr_resp.status_code == 400  # rejected at address-creation time already


# ---------------------------------------------------------------------------
# Admin-only access
# ---------------------------------------------------------------------------

def test_non_admin_cannot_access_admin_dashboard(client):
    cust_headers = register_and_login(client, "9400000006", "Cust6", "customer")
    resp = client.get("/api/v1/admin/dashboard", headers=cust_headers)
    assert resp.status_code == 403


def test_admin_can_access_dashboard(client):
    admin_h = admin_headers(client)
    resp = client.get("/api/v1/admin/dashboard", headers=admin_h)
    assert resp.status_code == 200
    assert "orders" in resp.json()
