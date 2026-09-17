import logging

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError

from app.core.config import settings
from app.core.database import Base, engine
from app.routers import auth, categories, products, search, cart, addresses, orders, delivery, admin

logger = logging.getLogger("local_saathi")
logging.basicConfig(level=logging.INFO)

# Creates all tables on startup if they don't exist yet (dev convenience;
# use Alembic migrations in production instead of create_all).
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Local Saathi API",
    description="Rural local same-day delivery & marketplace platform backend.",
    version="0.1.0",
)

# CORS (requirement #28) — permissive by default for local dev; set
# CORS_ALLOWED_ORIGINS (comma-separated) in production to lock this down
# to your actual Android/web client origins.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# requirement #20 — never leak a raw Python traceback to the client.
# Full detail still goes to the server log for debugging.
@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(status_code=500, content={"detail": "कुछ गलत हो गया, कृपया बाद में कोशिश करें।"})


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    # Keep FastAPI's normal {"detail": ...} shape — just centralized so
    # every error response, expected or not, has the same structure.
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail}, headers=exc.headers)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(status_code=422, content={"detail": "Input data गलत है।", "errors": exc.errors()})


app.include_router(auth.router)
app.include_router(categories.router)
app.include_router(products.router)
app.include_router(search.router)
app.include_router(cart.router)
app.include_router(addresses.router)
app.include_router(orders.router)
app.include_router(delivery.router)
app.include_router(admin.router)


@app.get("/")
def root():
    return {"message": "Local Saathi API चल रहा है।", "docs": "/docs"}
