"""
Run once after first setup:  python seed.py

Creates: starter categories (requirement #12), one delivery zone, and one
admin user so you can log in and start approving sellers/delivery partners.
Change the admin phone/password before real deployment.
"""
from app.core.database import Base, engine, SessionLocal
from app.core.security import hash_password
from app.models.category import Category
from app.models.address import DeliveryZone
from app.models.user import User, UserRole

Base.metadata.create_all(bind=engine)
db = SessionLocal()

if not db.query(Category).first():
    categories = [
        ("आटा", "Atta", "grocery"), ("चावल", "Rice", "grocery"), ("दाल", "Dal", "grocery"),
        ("तेल", "Oil", "grocery"), ("नमक", "Salt", "grocery"), ("चीनी", "Sugar", "grocery"),
        ("मसाले", "Spices", "grocery"), ("चाय", "Tea", "grocery"), ("बिस्किट", "Biscuits", "grocery"),
        ("नमकीन", "Namkeen", "grocery"), ("साबुन", "Soap", "grocery"), ("शैम्पू", "Shampoo", "grocery"),
        ("टूथपेस्ट", "Toothpaste", "grocery"), ("डिटर्जेंट", "Detergent", "grocery"),
        ("दूध", "Milk", "dairy"), ("दही", "Curd", "dairy"), ("छाछ", "Buttermilk", "dairy"),
        ("पनीर", "Paneer", "dairy"), ("मक्खन", "Butter", "dairy"), ("घी", "Ghee", "dairy"),
        ("सब्जियाँ", "Vegetables", "fresh"), ("फल", "Fruits", "fresh"), ("अंडे", "Eggs", "fresh"),
        ("ब्रेड", "Bread", "bakery"), ("केक", "Cake", "bakery"),
        ("स्थानीय उत्पाद", "Local products", "village"),
    ]
    for i, (hi, en, _group) in enumerate(categories):
        db.add(Category(name_hi=hi, name_en=en, sort_order=i, is_active=True))

if not db.query(DeliveryZone).first():
    db.add(DeliveryZone(name="Test Village", pincode="000000", is_active=True))

if not db.query(User).filter(User.phone == "9999999999").first():
    db.add(User(
        phone="9999999999", name="Admin", role=UserRole.admin,
        password_hash=hash_password("admin123"), is_active=True,
    ))

db.commit()
db.close()
print("Seed complete: categories, test delivery zone (pincode 000000), admin user (9999999999 / admin123).")
