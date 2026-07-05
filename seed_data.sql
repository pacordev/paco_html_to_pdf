-- Seed data for invoice.html template
-- 1 company · 5 clients · 15 invoices (3/client) · 5-7 line items each
-- Tax rate: 13% Ontario HST

-- ============================================================
-- COMPANY
-- ============================================================
INSERT INTO companies (name, address, city_state_zip, email, phone, logo_path, footer_text)
VALUES (
    'AlienDev',
    '123 King Street West, Suite 400',
    'Toronto, ON  M5H 1J9',
    'billing@aliendev.ca',
    '416-555-0100',
    'aliendev.png',
    'Thank you for your business! Payment is due within 30 days of the invoice date. Please reference the invoice number on your payment.'
);
-- company_id = 1

-- ============================================================
-- CLIENTS
-- ============================================================
INSERT INTO clients (name, email, phone) VALUES
    ('GTA Auto Repair Inc.',      'accounts@gtaautorepair.ca',     '416-555-0201'),
    ('Maple Leaf Motors',         'parts@mapleleafmotors.ca',      '905-555-0302'),
    ('King Street Garage',        'service@kingstreetgarage.ca',   '416-555-0403'),
    ('Scarborough Auto Centre',   'purchasing@scarboroughauto.ca', '416-555-0504'),
    ('North York Transmission',   'orders@nytransmission.ca',      '416-555-0605');
-- client_ids = 1..5

-- ============================================================
-- INVOICES  (subtotal/tax_amount/total pre-calculated)
-- tax_rate = 13.00 (Ontario HST)
-- ============================================================
INSERT INTO invoices
    (invoice_number, invoice_date, due_date, company_id, client_id,
     subtotal, tax_rate, tax_amount, total, notes)
VALUES
-- Client 1 – GTA Auto Repair Inc.
('INV-2026-001', '2026-01-05', '2026-02-04', 1, 1,  394.00, 13.00,  51.22,  445.22, 'Standard parts order. Deliver to service bay.'),
('INV-2026-002', '2026-02-03', '2026-03-05', 1, 1,  533.00, 13.00,  69.29,  602.29, 'Engine ancillaries — priority order.'),
('INV-2026-003', '2026-03-02', '2026-04-01', 1, 1,  712.00, 13.00,  92.56,  804.56, 'Suspension & steering kit order.'),

-- Client 2 – Maple Leaf Motors
('INV-2026-004', '2026-01-08', '2026-02-07', 1, 2,  694.00, 13.00,  90.22,  784.22, 'Fuel system & sensor package.'),
('INV-2026-005', '2026-02-10', '2026-03-12', 1, 2,  540.00, 13.00,  70.20,  610.20, 'Starting & steering components.'),
('INV-2026-006', '2026-03-15', '2026-04-14', 1, 2,  484.00, 13.00,  62.92,  546.92, 'Cooling system rebuild kit.'),

-- Client 3 – King Street Garage
('INV-2026-007', '2026-01-12', '2026-02-11', 1, 3,  671.00, 13.00,  87.23,  758.23, 'Exhaust & emissions components.'),
('INV-2026-008', '2026-02-18', '2026-03-20', 1, 3,  505.00, 13.00,  65.65,  570.65, 'Engine gasket & timing set.'),
('INV-2026-009', '2026-03-20', '2026-04-19', 1, 3,  718.00, 13.00,  93.34,  811.34, 'Transmission service package.'),

-- Client 4 – Scarborough Auto Centre
('INV-2026-010', '2026-01-15', '2026-02-14', 1, 4,  734.00, 13.00,  95.42,  829.42, 'Wheel bearing & steering linkage order.'),
('INV-2026-011', '2026-02-22', '2026-03-24', 1, 4,  519.00, 13.00,  67.47,  586.47, 'Ignition system components.'),
('INV-2026-012', '2026-03-25', '2026-04-24', 1, 4,  587.00, 13.00,  76.31,  663.31, 'Fuel injection & sensor bundle.'),

-- Client 5 – North York Transmission
('INV-2026-013', '2026-01-20', '2026-02-19', 1, 5,  901.00, 13.00, 117.13, 1018.13, 'ABS & brake system overhaul.'),
('INV-2026-014', '2026-02-25', '2026-03-27', 1, 5,  715.00, 13.00,  92.95,  807.95, 'Climate control system parts.'),
('INV-2026-015', '2026-03-28', '2026-04-27', 1, 5,  711.00, 13.00,  92.43,  803.43, 'Lighting & electrical accessories.');
-- invoice_ids = 1..15

-- ============================================================
-- INVOICE ITEMS  (line_total is a generated column — omitted)
-- ============================================================

-- ---- INV-2026-001  subtotal $394.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(1, 'Front Brake Pads Set',           2,  45.00),
(1, 'Front Brake Rotor',              2,  65.00),
(1, 'Engine Oil Filter',              4,  12.50),
(1, 'Engine Air Filter',              2,  18.00),
(1, 'Spark Plug Set (x4)',            2,  28.00),
(1, 'Serpentine Belt',                1,  32.00);

-- ---- INV-2026-002  subtotal $533.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(2, 'Alternator',                     1, 220.00),
(2, 'Serpentine Belt',                1,  32.00),
(2, 'Coolant Upper Hose',             2,  22.00),
(2, 'Thermostat',                     1,  22.00),
(2, 'Water Pump',                     1,  95.00),
(2, 'Timing Belt',                    1,  85.00),
(2, 'Valve Cover Gasket',             1,  35.00);

-- ---- INV-2026-003  subtotal $712.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(3, 'Front Strut Assembly',           2, 135.00),
(3, 'Rear Shock Absorber',            2,  89.00),
(3, 'Wheel Bearing Hub Assembly',     1, 125.00),
(3, 'CV Joint Boot Kit',              2,  35.00),
(3, 'Rear Brake Pads Set',            1,  45.00),
(3, 'PCV Valve',                      2,  12.00);

-- ---- INV-2026-004  subtotal $694.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(4, 'Fuel Pump',                      1, 175.00),
(4, 'Fuel Filter',                    3,  18.00),
(4, 'Oxygen Sensor',                  2,  78.00),
(4, 'Mass Air Flow Sensor',           1, 145.00),
(4, 'Throttle Position Sensor',       1,  65.00),
(4, 'Cabin Air Filter',               3,  15.00),
(4, 'Engine Air Filter',              3,  18.00);

-- ---- INV-2026-005  subtotal $540.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(5, 'Starter Motor',                  1, 195.00),
(5, 'Battery Terminal Connectors',    2,  12.00),
(5, 'Power Steering Pump',            1, 165.00),
(5, 'Power Steering Hose',            1,  55.00),
(5, 'Idler Pulley',                   2,  28.00),
(5, 'Belt Tensioner Pulley',          1,  45.00);

-- ---- INV-2026-006  subtotal $484.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(6, 'Radiator',                       1, 210.00),
(6, 'Radiator Cap',                   2,   8.00),
(6, 'Coolant Reservoir',              1,  35.00),
(6, 'Coolant Lower Hose',             2,  20.00),
(6, 'Coolant Upper Hose',             2,  22.00),
(6, 'Thermostat',                     2,  22.00),
(6, 'Water Pump',                     1,  95.00);

-- ---- INV-2026-007  subtotal $671.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(7, 'Catalytic Converter',            1, 350.00),
(7, 'Exhaust Manifold Gasket',        1,  28.00),
(7, 'Oxygen Sensor (Upstream)',       1,  78.00),
(7, 'Oxygen Sensor (Downstream)',     1,  78.00),
(7, 'EGR Valve',                      1,  95.00),
(7, 'EGR Tube',                       1,  42.00);

-- ---- INV-2026-008  subtotal $505.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(8, 'Head Gasket Set',                1, 125.00),
(8, 'Valve Cover Gasket',             2,  35.00),
(8, 'Intake Manifold Gasket',         1,  45.00),
(8, 'Exhaust Manifold Gasket',        1,  28.00),
(8, 'Timing Chain Kit',               1, 185.00),
(8, 'Oil Pan Gasket',                 1,  22.00),
(8, 'Crankshaft Seal',                2,  15.00);

-- ---- INV-2026-009  subtotal $718.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(9, 'Transmission Filter Kit',        2,  55.00),
(9, 'Transmission Fluid (1L)',       10,  12.00),
(9, 'Differential Fluid (1L)',        4,  14.00),
(9, 'Transfer Case Fluid (1L)',       2,  16.00),
(9, 'Clutch Kit',                     1, 245.00),
(9, 'Flywheel',                       1, 155.00);

-- ---- INV-2026-010  subtotal $734.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(10, 'Front Wheel Bearing Hub Assembly', 2, 125.00),
(10, 'Rear Wheel Bearing Hub Assembly',  2, 115.00),
(10, 'Outer Tie Rod End',                2,  32.00),
(10, 'Inner Tie Rod End',                2,  28.00),
(10, 'Lower Ball Joint',                 2,  45.00),
(10, 'Sway Bar End Link Kit',            2,  22.00);

-- ---- INV-2026-011  subtotal $519.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(11, 'Ignition Coil',                 4,  48.00),
(11, 'Spark Plug Set (x4)',           2,  28.00),
(11, 'Spark Plug Wire Set',           1,  55.00),
(11, 'Distributor Cap',               1,  35.00),
(11, 'Distributor Rotor',             1,  18.00),
(11, 'Crankshaft Position Sensor',    1,  85.00),
(11, 'Camshaft Position Sensor',      1,  78.00);

-- ---- INV-2026-012  subtotal $587.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(12, 'Fuel Injector',                 4,  65.00),
(12, 'Fuel Pressure Regulator',       1,  55.00),
(12, 'Fuel Rail',                     1,  95.00),
(12, 'Intake Air Temperature Sensor', 1,  45.00),
(12, 'MAP Sensor',                    1,  68.00),
(12, 'Coolant Temperature Sensor',    2,  32.00);

-- ---- INV-2026-013  subtotal $901.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(13, 'ABS Wheel Speed Sensor (Front)', 2,  58.00),
(13, 'ABS Wheel Speed Sensor (Rear)',  2,  55.00),
(13, 'ABS Control Module',             1, 285.00),
(13, 'Brake Master Cylinder',          1, 115.00),
(13, 'Brake Booster',                  1, 145.00),
(13, 'Front Brake Caliper',            2,  65.00);

-- ---- INV-2026-014  subtotal $715.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(14, 'AC Compressor',                 1, 295.00),
(14, 'AC Condenser',                  1, 185.00),
(14, 'AC Receiver Drier',             1,  55.00),
(14, 'AC Expansion Valve',            1,  45.00),
(14, 'AC Drive Belt',                 1,  25.00),
(14, 'Blower Motor',                  1,  78.00),
(14, 'Blower Motor Resistor',         1,  32.00);

-- ---- INV-2026-015  subtotal $711.00 ----
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(15, 'Windshield Wiper Motor',        1,  95.00),
(15, 'Wiper Blade Set',               3,  22.00),
(15, 'Headlight Assembly (Driver)',   1, 145.00),
(15, 'Headlight Assembly (Passenger)',1, 145.00),
(15, 'Tail Light Assembly',           2,  85.00),
(15, 'Turn Signal Switch',            1,  55.00),
(15, 'Horn Assembly',                 1,  35.00);
