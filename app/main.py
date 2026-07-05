import re

from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import HTMLResponse, Response
from jinja2 import Environment, FileSystemLoader

from app.db import get_connection
from app.pdf import html_to_pdf

app = FastAPI(title="PrintPDF Invoice API")

jinja_env = Environment(loader=FileSystemLoader("templates"), autoescape=True)

INVOICE_QUERY = """
    SELECT
        i.id, i.invoice_number, i.invoice_date, i.due_date,
        i.subtotal, i.tax_rate, i.tax_amount, i.total, i.notes,
        c.name AS company_name, c.address AS company_address,
        c.city_state_zip AS company_city_state_zip,
        c.email AS company_email, c.phone AS company_phone,
        c.logo_path AS company_logo, c.footer_text,
        cl.name AS client_name, cl.email AS client_email, cl.phone AS client_phone
    FROM invoices i
    JOIN companies c ON c.id = i.company_id
    JOIN clients cl ON cl.id = i.client_id
    WHERE i.invoice_number = %s
"""

ITEMS_QUERY = """
    SELECT description, quantity, unit_price, line_total
    FROM invoice_items
    WHERE invoice_id = %s
    ORDER BY id
"""

UNSAFE_FILENAME_CHARS = re.compile(r"[^A-Za-z0-9._-]+")


def fetch_invoice(invoice_number: str, contact: str):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(INVOICE_QUERY, (invoice_number,))
            invoice = cur.fetchone()

            if invoice is None:
                raise HTTPException(status_code=404, detail="Invoice not found")

            if contact.strip().lower() not in (
                (invoice["client_email"] or "").lower(),
                (invoice["client_phone"] or "").lower(),
            ):
                raise HTTPException(status_code=403, detail="Contact does not match this invoice's client")

            cur.execute(ITEMS_QUERY, (invoice["id"],))
            products = cur.fetchall()

    return invoice, products


def render_invoice_html(invoice, products) -> str:
    template = jinja_env.get_template("invoice.html")
    return template.render(
        invoice_number=invoice["invoice_number"],
        invoice_date=invoice["invoice_date"].strftime("%Y-%m-%d"),
        due_date=invoice["due_date"].strftime("%Y-%m-%d"),
        company_name=invoice["company_name"],
        company_address=invoice["company_address"],
        company_city_state_zip=invoice["company_city_state_zip"],
        company_email=invoice["company_email"],
        company_phone=invoice["company_phone"],
        company_logo=invoice["company_logo"],
        footer_text=invoice["footer_text"],
        client_name=invoice["client_name"],
        products=products,
        subtotal=invoice["subtotal"],
        tax_rate=invoice["tax_rate"],
        tax_amount=invoice["tax_amount"],
        total=invoice["total"],
        notes=invoice["notes"],
    )


def sanitize_filename(name: str) -> str:
    name = UNSAFE_FILENAME_CHARS.sub("-", name.strip()).strip("-")
    return name or "invoice"


@app.get("/invoices/{invoice_number}", response_class=HTMLResponse)
def render_invoice(
    invoice_number: str,
    contact: str = Query(..., description="Client email or phone number, used to authorize the request"),
):
    invoice, products = fetch_invoice(invoice_number, contact)
    html = render_invoice_html(invoice, products)
    return HTMLResponse(content=html)


@app.get("/createpdf/{invoice_number}")
def create_pdf(
    invoice_number: str,
    contact: str = Query(..., description="Client email or phone number, used to authorize the request"),
    filename: str = Query(None, description="Name for the downloaded PDF file, without extension"),
):
    invoice, products = fetch_invoice(invoice_number, contact)
    html = render_invoice_html(invoice, products)
    pdf_bytes = html_to_pdf(html)

    safe_name = sanitize_filename(filename or invoice["invoice_number"])
    headers = {"Content-Disposition": f'attachment; filename="{safe_name}.pdf"'}
    return Response(content=pdf_bytes, media_type="application/pdf", headers=headers)
