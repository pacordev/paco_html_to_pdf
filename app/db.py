# Database connection helper shared by the API endpoints.
#
# DATABASE_URL defaults to a local Postgres instance, but is overridden via
# environment variable in Docker Compose (pointing at the "db" service).

import os

import psycopg
from psycopg.rows import dict_row

DATABASE_URL = os.environ.get(
    "DATABASE_URL", "postgresql://printpdf:printpdf@localhost:5432/printpdf"
)


def get_connection():
    # dict_row lets callers access columns by name (e.g. row["invoice_number"])
    # instead of positional tuple indices.
    return psycopg.connect(DATABASE_URL, row_factory=dict_row)
