"""
Central configuration. Reads from environment variables so secrets are
NEVER hard-coded in source (requirement #48/#64).

For local dev, create a `.env` file (see .env.example) — it's loaded
automatically below — or export these as real environment variables
before running the server. `.env` itself must never be committed (see
.gitignore).
"""
import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    # SECURITY: set a strong random value in production via env var.
    SECRET_KEY: str = os.getenv("LOCAL_SAATHI_SECRET_KEY", "dev-only-change-me")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))

    # Dev default = SQLite file. Swap to a PostgreSQL URL in production, e.g.
    # postgresql+psycopg2://user:pass@host:5432/local_saathi
    _raw_db_url = os.getenv("DATABASE_URL", "sqlite:///./local_saathi.db")
    DATABASE_URL: str = (
        _raw_db_url.replace("postgres://", "postgresql://", 1)
        if _raw_db_url.startswith("postgres://")
        else _raw_db_url
    )

    # Comma-separated list, e.g. "https://app.localsaathi.in,https://admin.localsaathi.in"
    # Dev default (*) is permissive on purpose — lock this down before
    # going to production (requirement #28).
    CORS_ALLOWED_ORIGINS: list[str] = (
        os.getenv("CORS_ALLOWED_ORIGINS", "*").split(",")
    )


settings = Settings()
