-- Schema for invoice.html template
-- Tables: companies, clients, invoices, invoice_items

CREATE TABLE companies (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(255)  NOT NULL,
    address     VARCHAR(255),
    city_state_zip VARCHAR(100),
    email       VARCHAR(150),
    phone       VARCHAR(30),
    logo_path   TEXT,
    footer_text TEXT,
    created_at  TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE clients (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    email      VARCHAR(150),
    phone      VARCHAR(30),
    created_at TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE invoices (
    id             SERIAL PRIMARY KEY,
    invoice_number VARCHAR(50)     NOT NULL UNIQUE,
    invoice_date   DATE            NOT NULL,
    due_date       DATE            NOT NULL,
    company_id     INT             NOT NULL REFERENCES companies(id),
    client_id      INT             NOT NULL REFERENCES clients(id),
    subtotal       NUMERIC(12, 2)  NOT NULL DEFAULT 0,
    tax_rate       NUMERIC(5, 2)   NOT NULL DEFAULT 0,  -- e.g. 8.25 means 8.25%
    tax_amount     NUMERIC(12, 2)  NOT NULL DEFAULT 0,
    total          NUMERIC(12, 2)  NOT NULL DEFAULT 0,
    notes          TEXT,
    created_at     TIMESTAMPTZ     DEFAULT NOW()
);

CREATE TABLE invoice_items (
    id           SERIAL PRIMARY KEY,
    invoice_id   INT             NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    description  TEXT            NOT NULL,
    quantity     NUMERIC(10, 2)  NOT NULL DEFAULT 1,
    unit_price   NUMERIC(12, 2)  NOT NULL DEFAULT 0,
    line_total   NUMERIC(12, 2)  GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- Index for common lookups
CREATE INDEX idx_invoices_company   ON invoices(company_id);
CREATE INDEX idx_invoices_client    ON invoices(client_id);
CREATE INDEX idx_invoice_items_inv  ON invoice_items(invoice_id);
