from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_role, get_current_user
from app.models.user import User
from app.models.seller import Seller
from app.models.product import Product, ProductKeyword, StockStatus
from app.models.category import Category
from app.models.tracking import AdminAction
from app.schemas.product import ProductCreate, ProductOut, ProductStockUpdate, ProductUpdate

router = APIRouter(prefix="/api/v1/products", tags=["products"])


def _get_owned_product_or_403(db: Session, product_id: int, user: User) -> Product:
    """
    Shared ownership check for requirement #12 — a seller can only touch
    their own products; admin can touch any. Raises 404 if the product
    doesn't exist at all (don't leak existence info beyond that).
    """
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product नहीं मिला।")
    if user.role.value == "admin":
        return product
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller or product.seller_id != seller.id:
        raise HTTPException(status_code=403, detail="यह product आपका नहीं है।")
    return product


@router.get("", response_model=list[ProductOut])
def list_products(
    category_id: int | None = None,
    seller_id: int | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(Product).filter(Product.is_active == True)  # noqa: E712
    if category_id is not None:
        query = query.filter(Product.category_id == category_id)
    if seller_id is not None:
        query = query.filter(Product.seller_id == seller_id)
    return query.all()


@router.post("", response_model=ProductOut)
def create_product(
    payload: ProductCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["seller"])),
):
    seller = db.query(Seller).filter(Seller.user_id == current_user.id).first()
    if not seller or not seller.is_approved:
        raise HTTPException(status_code=403, detail="आपकी shop अभी admin से approve नहीं हुई है।")

    # If seller picked no category (or an inactive/unknown one), the product
    # is filed as "Other" — this is the mandatory workflow from requirement
    # #14: it must still show up normally to customers and in search.
    category = None
    is_other = True
    if payload.category_id is not None:
        category = db.query(Category).filter(
            Category.id == payload.category_id, Category.is_active == True  # noqa: E712
        ).first()
        is_other = category is None

    product = Product(
        seller_id=seller.id,
        category_id=category.id if category else None,
        is_other=is_other,
        name=payload.name,
        description=payload.description,
        price=payload.price,
        unit=payload.unit,
        available_qty=payload.available_qty,
        min_order_qty=payload.min_order_qty,
        stock_status=StockStatus.in_stock if payload.available_qty > 0 else StockStatus.out_of_stock,
        image_url=payload.image_url,
        is_active=True,
    )
    db.add(product)
    db.flush()

    for kw in payload.keywords:
        kw = kw.strip()
        if kw:
            db.add(ProductKeyword(product_id=product.id, keyword=kw))

    db.commit()
    db.refresh(product)
    return product


@router.patch("/{product_id}/stock", response_model=ProductOut)
def update_stock(
    product_id: int,
    payload: ProductStockUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["seller"])),
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product नहीं मिला।")

    seller = db.query(Seller).filter(Seller.user_id == current_user.id).first()
    if not seller or product.seller_id != seller.id:
        raise HTTPException(status_code=403, detail="यह product आपका नहीं है।")

    if payload.stock_status not in [s.value for s in StockStatus]:
        raise HTTPException(status_code=400, detail="Invalid stock status.")

    product.available_qty = payload.available_qty
    product.stock_status = payload.stock_status
    db.commit()
    db.refresh(product)
    return product


@router.put("/{product_id}", response_model=ProductOut)
def update_product(
    product_id: int,
    payload: ProductUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Edit a product's own details (requirement #12/#21). Seller can edit
    only their own products; admin can edit any. Price and category
    changes are written to the audit log (requirement #24).
    """
    if current_user.role.value not in ("seller", "admin"):
        raise HTTPException(status_code=403, detail="इस action की अनुमति आपको नहीं है।")

    product = _get_owned_product_or_403(db, product_id, current_user)
    changes = payload.model_dump(exclude_unset=True)

    if "category_id" in changes:
        if changes["category_id"] is not None:
            category = db.query(Category).filter(
                Category.id == changes["category_id"], Category.is_active == True  # noqa: E712
            ).first()
            if not category:
                raise HTTPException(status_code=404, detail="Category नहीं मिली।")
            product.is_other = False
        else:
            # Seller explicitly cleared the category — files back under Other.
            product.is_other = True

    if "price" in changes and changes["price"] != product.price:
        db.add(AdminAction(
            admin_user_id=current_user.id, action="update_product_price",
            entity_type="product", entity_id=product.id,
            old_value=str(product.price), new_value=str(changes["price"]),
        ))

    for field, value in changes.items():
        setattr(product, field, value)

    db.commit()
    db.refresh(product)
    return product


@router.delete("/{product_id}")
def deactivate_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Soft-delete only (requirement #21) — a hard delete would corrupt
    historical orders that reference this product (requirement #21/#22).
    """
    if current_user.role.value not in ("seller", "admin"):
        raise HTTPException(status_code=403, detail="इस action की अनुमति आपको नहीं है।")

    product = _get_owned_product_or_403(db, product_id, current_user)
    product.is_active = False
    db.add(AdminAction(
        admin_user_id=current_user.id, action="deactivate_product",
        entity_type="product", entity_id=product.id,
        old_value="active", new_value="inactive",
    ))
    db.commit()
    return {"message": "Product निष्क्रिय कर दिया गया।"}


@router.post("/{product_id}/move-category", response_model=ProductOut)
def move_other_product_to_category(
    product_id: int,
    category_id: int = Query(...),
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["admin"])),
):
    """
    Admin moves an 'Other' product into an official category (requirement
    #20). The product row is updated in place — never deleted — so its
    order/search history stays intact.
    """
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product नहीं मिला।")
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category नहीं मिली।")

    old_value = "other" if product.is_other else str(product.category_id)
    product.category_id = category.id
    product.is_other = False
    db.commit()
    db.refresh(product)

    db.add(AdminAction(
        admin_user_id=admin.id, action="move_product_category",
        entity_type="product", entity_id=product.id,
        old_value=old_value, new_value=category.name_en,
    ))
    db.commit()
    return product


@router.get("/other/list", response_model=list[ProductOut])
def list_other_products(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(["admin"])),
):
    """Admin view of all Other/Uncategorized products (requirement #19)."""
    return db.query(Product).filter(Product.is_other == True).all()  # noqa: E712
