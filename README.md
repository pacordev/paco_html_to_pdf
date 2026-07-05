# Paco's HTML PDF Generator

A small FastAPI microservice that fills an invoice HTML template with data
pulled from a Postgres database, and can render it either as HTML or as a
downloadable PDF (via `wkhtmltopdf`). The templating/rendering approach can
be reused for any HTML template of the same style.

## Tech stack

- **[FastAPI](https://fastapi.tiangolo.com/)** — Python web framework serving the API
- **[Uvicorn](https://www.uvicorn.org/)** — ASGI server used to run the app
- **[Jinja2](https://jinja.palletsprojects.com/)** — template engine that fills `invoice.html` with data
- **[PostgreSQL 16](https://www.postgresql.org/)** — relational database storing companies, clients, invoices, and line items
- **[psycopg 3](https://www.psycopg.org/psycopg3/)** — PostgreSQL driver used by the app
- **[Docker / Docker Compose](https://www.docker.com/)** — runs both the Postgres database and the API as containers
- **[wkhtmltopdf](https://wkhtmltopdf.org/)** — converts the rendered HTML into a PDF
- **[pdfkit](https://pypi.org/project/pdfkit/)** — Python wrapper around the `wkhtmltopdf` binary

## What it does

1. A Postgres database (run via Docker) stores companies, clients, invoices,
   and invoice line items (currently using synthetic data).
2. A FastAPI app exposes endpoints that, given an **invoice number** and a
   **client contact** (email or phone), look up the invoice in the database
   and fill in the `invoice.html` template with the data (company info,
   client info, line items, totals) — returned either as rendered HTML or
   as a generated PDF file.
3. The contact parameter acts as a lightweight authorization check: the
   request is only fulfilled if the contact matches the email or phone on
   file for that invoice's client (simple business rule).

## Project layout

```
printpdf/
├── docker-compose.yml     # Defines the db and api containers
├── Dockerfile             # Builds the FastAPI app image
├── schema.sql             # Database schema (auto-run on first container start)
├── seed_data.sql          # Synthetic sample data (auto-run on first container start)
├── invoice.html           # Original invoice template (reference copy)
├── aliendev.png           # Sample company logo used by the seed data
├── requirements.txt       # Python dependencies
├── app/
│   ├── main.py            # FastAPI app: /invoices and /createpdf endpoints
│   ├── db.py              # Database connection helper
│   └── pdf.py             # Renders HTML to PDF bytes via wkhtmltopdf/pdfkit
└── templates/
    ├── invoice.html        # Jinja2 version of the invoice template (used by the app)
    └── aliendev.png
```

## The database

### `schema.sql`

Defines four tables used to model a simple invoicing system:

- **`companies`** — the business issuing invoices (name, address, contact
  info, logo, footer text).
- **`clients`** — the customers being billed (name, email, phone).
- **`invoices`** — one row per invoice, linked to a company and a client,
  with dates, subtotal/tax/total amounts, and free-text notes.
- **`invoice_items`** — the line items on an invoice (description, quantity,
  unit price). `line_total` is a generated column (`quantity * unit_price`).

Foreign keys tie `invoices` to `companies`/`clients`, and `invoice_items` to
`invoices` (with `ON DELETE CASCADE`). Indexes are added on the foreign key
columns for lookup performance.

### `seed_data.sql`

Synthetic data used for local development and testing:

- 1 company (**AlienDev**, a fictional auto-parts supplier)
- 5 clients (auto repair shops around Toronto/GTA)
- 15 invoices (3 per client, dated across Jan–Mar 2026), each with a
  13% Ontario HST tax rate and pre-calculated subtotal/tax/total
- ~5-7 line items per invoice (auto parts and services)

Both files are mounted into the Postgres container's
`/docker-entrypoint-initdb.d/` directory and run automatically, in order,
the **first time** the container starts with an empty data volume.

## The API

### `GET /invoices/{invoice_number}`

Renders an invoice as HTML.

**Path parameter**
- `invoice_number` — e.g. `INV-2026-001`

**Query parameter**
- `contact` (required) — the client's email or phone number on file for
  that invoice. Used as a simple authorization check.

**Responses**
- `200 OK` — returns the rendered invoice as HTML
- `403 Forbidden` — the invoice exists, but `contact` doesn't match the
  client's email or phone
- `404 Not Found` — no invoice with that number exists

**Example**

```
GET /invoices/INV-2026-001?contact=accounts@gtaautorepair.ca
GET /invoices/INV-2026-001?contact=416-555-0201
```

### `GET /createpdf/{invoice_number}`

Renders the same invoice data and converts it to a PDF file (via
`wkhtmltopdf`), returned as a downloadable attachment.

**Path parameter**
- `invoice_number` — e.g. `INV-2026-001`

**Query parameters**
- `contact` (required) — the client's email or phone number on file for
  that invoice. Used as a simple authorization check.
- `filename` (optional) — name for the downloaded file, without the `.pdf`
  extension. Defaults to the invoice number. Unsafe characters are stripped.

**Responses**
- `200 OK` — returns `application/pdf` bytes with a
  `Content-Disposition: attachment; filename="<name>.pdf"` header
- `403 Forbidden` — the invoice exists, but `contact` doesn't match the
  client's email or phone
- `404 Not Found` — no invoice with that number exists

**Example**

```
GET /createpdf/INV-2026-001?contact=accounts@gtaautorepair.ca&filename=invoice-jan
```

### Testing with Postman

1. Make sure the database is running (`docker compose up -d`) and the API is
   running (`uvicorn app.main:app --reload`).
2. Open Postman and create a new request:
   - **Method:** `GET`
   - **URL:** `http://127.0.0.1:8000/invoices/INV-2026-001`
3. Go to the **Params** tab and add a query parameter:
   - **Key:** `contact`
   - **Value:** `accounts@gtaautorepair.ca` (or `416-555-0201`)

   Postman will build the full URL for you:
   `http://127.0.0.1:8000/invoices/INV-2026-001?contact=accounts@gtaautorepair.ca`
4. Click **Send**. You should get a `200 OK` response with the rendered
   invoice HTML in the response body — click the **Preview** tab in Postman
   to view it rendered instead of as raw text.
5. To see the error responses, try:
   - An invoice number that doesn't exist (e.g. `INV-9999-999`) → `404`
   - A `contact` value that doesn't match the client on file → `403`
6. To test PDF generation, repeat the same steps against
   `http://127.0.0.1:8000/createpdf/INV-2026-001`, optionally adding a
   `filename` query param. Click **Send**, then use Postman's **Save
   Response > Save to a file** option to download and open the generated
   PDF.

You can find other sample `invoice_number`/`contact` pairs by querying the
seeded data directly:

```bash
docker exec -it printpdf-db psql -U printpdf -d printpdf -c \
  "SELECT invoice_number, c.email, c.phone FROM invoices i JOIN clients c ON c.id = i.client_id;"
```

## Running it locally

Both the database and the API run as containers, orchestrated by Docker
Compose — this mirrors how the service would run in a real deployment,
with no local Python installation required.

### Prerequisites

- [Docker](https://www.docker.com/) (with Docker Compose)

### 1. Clone the repo

```bash
git clone <repo-url>
cd printpdf
```

### 2. Build and start everything

```bash
docker compose up -d --build
```

This builds the API image from the `Dockerfile` and starts two containers:

- **`printpdf-db`** — Postgres 16. On first start (empty data volume) it
  automatically runs `schema.sql` followed by `seed_data.sql` to create the
  tables and load the sample data.
- **`printpdf-api`** — the FastAPI app, served with Uvicorn. It waits for
  the database's healthcheck to pass before starting, and connects to it
  over the internal Docker network at `db:5432` (via the `DATABASE_URL`
  environment variable set in `docker-compose.yml`).

Default connection details (used inside the Docker network, and also
reachable from your host machine since the port is published):

| Setting  | Value       |
|----------|-------------|
| Host     | `localhost` (`db` from inside the Docker network) |
| Port     | `5432`      |
| Database | `printpdf`  |
| User     | `printpdf`  |
| Password | `printpdf`  |

To verify the database loaded correctly:

```bash
docker exec -it printpdf-db psql -U printpdf -d printpdf -c "SELECT count(*) FROM invoices;"
# should return 15
```

> If you ever change `schema.sql` or `seed_data.sql`, the init scripts only
> re-run on an **empty** data volume. Reset with:
> `docker compose down -v && docker compose up -d --build`

### 3. Try it out

The API is published on `http://localhost:8000`, same as running it
locally:

```bash
curl "http://localhost:8000/invoices/INV-2026-001?contact=accounts@gtaautorepair.ca"
```

Or open that same URL in a browser to see the rendered invoice.
Interactive API docs are auto-generated by FastAPI at
`http://localhost:8000/docs`.

To download it as a PDF instead:

```bash
curl -o invoice.pdf "http://localhost:8000/createpdf/INV-2026-001?contact=accounts@gtaautorepair.ca&filename=invoice-jan"
```

You can also test it with Postman:

1. Create a new request with method `GET` and URL
   `http://localhost:8000/invoices/INV-2026-001`.
2. In the **Params** tab, add a query parameter `contact` with value
   `accounts@gtaautorepair.ca` (or `416-555-0201`).
3. Click **Send** — you should get a `200 OK` with the rendered invoice
   HTML in the body (use Postman's **Preview** tab to view it rendered).

See [Testing with Postman](#testing-with-postman) above for the full
walkthrough, including how to trigger the `403`/`404` error responses and
find other sample invoice/contact pairs.

### Useful commands

```bash
docker compose logs -f api     # tail the API's logs
docker compose down            # stop both containers (keeps the data volume)
docker compose down -v         # stop and wipe the database volume
docker compose up -d --build   # rebuild the API image after code changes
```

### Running the API outside Docker (optional)

If you'd rather run the API directly on your machine against the
containerized database:

```bash
docker compose up -d db
python3 -m venv .venv
source .venv/bin/activate      # on Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

The app defaults to `DATABASE_URL=postgresql://printpdf:printpdf@localhost:5432/printpdf`
when run this way, since `localhost` resolves correctly outside of Docker.

## Running it without Docker (bare-metal / VM setup)

If you're deploying to a server directly instead of using containers, here's
how to install the same pieces by hand. Commands below target Ubuntu/Debian
(`apt`); adjust package names for other distros (`dnf`, `yum`, `brew`, etc.).

### 1. Install PostgreSQL

```bash
sudo apt-get update
sudo apt-get install -y postgresql
sudo systemctl enable --now postgresql
```

Create the database, user, and load the schema + seed data:

```bash
sudo -u postgres psql -c "CREATE USER printpdf WITH PASSWORD 'printpdf';"
sudo -u postgres psql -c "CREATE DATABASE printpdf OWNER printpdf;"
psql "postgresql://printpdf:printpdf@localhost:5432/printpdf" -f schema.sql
psql "postgresql://printpdf:printpdf@localhost:5432/printpdf" -f seed_data.sql
```

Verify it loaded correctly:

```bash
psql "postgresql://printpdf:printpdf@localhost:5432/printpdf" -c "SELECT count(*) FROM invoices;"
# should return 15
```

### 2. Install wkhtmltopdf

`wkhtmltopdf` was dropped from Debian/Ubuntu's own package repos years ago
(it depends on a patched, unmaintained build of Qt/WebKit), so `apt install
wkhtmltopdf` will fail or install a broken/no-op stub. Install the official
`wkhtmltox` package instead — pick the `.deb` matching your OS release and
CPU architecture from the
[wkhtmltopdf/packaging releases](https://github.com/wkhtmltopdf/packaging/releases)
page. For example, on Debian 12 (bookworm), amd64:

```bash
sudo apt-get install -y fontconfig libfreetype6 libjpeg62-turbo libpng16-16 \
    libx11-6 libxcb1 libxext6 libxrender1 xfonts-75dpi xfonts-base
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb
sudo apt-get install -y ./wkhtmltox_0.12.6.1-3.bookworm_amd64.deb
```

Use `arm64` instead of `amd64` in the filename if you're on an ARM server
(e.g. AWS Graviton, Raspberry Pi), or the `.deb`/`.rpm` matching your distro
if it's not Debian-based. Verify the install:

```bash
wkhtmltopdf --version
```

### 3. Install Python and the app's dependencies

Requires Python 3.10+.

```bash
sudo apt-get install -y python3 python3-venv
git clone <repo-url>
cd printpdf
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 4. Configure and run the app

Point the app at your Postgres instance (skip this if you kept the same
`printpdf`/`printpdf`/`localhost:5432` defaults used above):

```bash
export DATABASE_URL="postgresql://printpdf:printpdf@localhost:5432/printpdf"
```

Run it directly with Uvicorn:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

For a production-style setup you'd normally run this behind a process
manager and reverse proxy (e.g. `systemd` + Uvicorn/Gunicorn workers behind
Nginx) instead of a raw `uvicorn` process, but that's outside the scope of
this local-testing setup.

Once running, the same endpoints and Postman instructions described above
under [The API](#the-api) apply — just swap `localhost:8000` for your
server's address.

## Roadmap

- [x] Convert the rendered HTML to a PDF file using `wkhtmltopdf`
- [x] Return the PDF as a downloadable file from the API
