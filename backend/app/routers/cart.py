from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_role
from app.models.user import User
from app.models.cart import Cart, CartItem
from app.models.product import Product, StockStatus
from app.schemas.order import CartItemAdd, CartItemUpdate

router = APIRouter(prefix="/api/v1/cart", tags=["cart"])


def _get_or_create_cart(db: Session, customer_id: int) -> Cart:
    cart = db.query(Cart).filter(Cart.customer_id == customer_id).first()
    if not cart:
        cart = Cart(customer_id=customer_id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    return cart


@router.get("")
def get_cart(db: Session = Depends(get_db), user: User = Depends(require_role(["customer"]))):
    cart = _get_or_create_cart(db, user.id)
    subtotal = sum(item.quantity * item.product.price for item in cart.items)
    return {
        "items": [
            {
                "id": item.id,
                "product_id": item.product_id,
                "name": item.product.name,
                "price": item.product.price,
                "quantity": item.quantity,
                "amount": round(item.quantity * item.product.price, 2),
            }
            for item in cart.items
        ],
        "subtotal": round(subtotal, 2),
    }


@router.post("/items")
def add_item(
    payload: CartItemAdd,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(["customer"])),
):
    product = db.query(Product).filter(Product.id == payload.product_id, Product.is_active == True).first()  # noqa: E712
    if not product:
        raise HTTPException(status_code=404, detail="Product नहीं मिला।")
    if product.stock_status == StockStatus.out_of_stock:
        raise HTTPException(status_code=400, detail="यह product अभी उपलब्ध नहीं है।")
    if payload.quantity < product.min_order_qty:
        raise HTTPException(status_code=400, detail=f"न्यूनतम order quantity {product.min_order_qty} है।")

    cart = _get_or_create_cart(db, user.id)
    existing = db.query(CartItem).filter(CartItem.cart_id == cart.id, CartItem.product_id == product.id).first()
    if existing:
        existing.quantity += payload.quantity
    else:
        db.add(CartItem(cart_id=cart.id, product_id=product.id, quantity=payload.quantity))
    db.commit()
    return {"message": "Cart में जोड़ा गया।"}


@router.put("/items/{item_id}")
def update_item(
    item_id: int,
    payload: CartItemUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(["customer"])),
):
    cart = _get_or_create_cart(db, user.id)
    item = db.query(CartItem).filter(CartItem.id == item_id, CartItem.cart_id == cart.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Cart item नहीं मिला।")
    if payload.quantity <= 0:
        db.delete(item)
    else:
        item.quantity = payload.quantity
    db.commit()
    return {"message": "Cart update हो गया।"}


@router.delete("/items/{item_id}")
def remove_item(
    item_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(["customer"])),
):
    cart = _get_or_create_cart(db, user.id)
    item = db.query(CartItem).filter(CartItem.id == item_id, CartItem.cart_id == cart.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Cart item नहीं मिला।")
    db.delete(item)
    db.commit()
    return {"message": "Item हटा दिया गया।"}
