import os
import tempfile

import pdfkit

TEMPLATES_DIR = "templates"

PDF_OPTIONS = {
    "enable-local-file-access": None,
    "quiet": None,
    # invoice.html sizes itself for Letter (8.5x11in) and already builds in
    # its own 1in padding via CSS, so wkhtmltopdf's own page margins and
    # auto-shrink must be turned off or the content gets letterboxed/shrunk
    # and appears centered on the page.
    "page-size": "Letter",
    "margin-top": "0",
    "margin-bottom": "0",
    "margin-left": "0",
    "margin-right": "0",
    "disable-smart-shrinking": None,
}


def html_to_pdf(html: str) -> bytes:
    """Render an HTML string to PDF bytes via wkhtmltopdf.

    Written to a temp file inside TEMPLATES_DIR (rather than passed as a
    string) so wkhtmltopdf can resolve the template's relative image paths
    (e.g. the company logo) against that directory.
    """
    fd, tmp_path = tempfile.mkstemp(suffix=".html", dir=TEMPLATES_DIR)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as tmp_file:
            tmp_file.write(html)
        return pdfkit.from_file(tmp_path, False, options=PDF_OPTIONS)
    finally:
        os.remove(tmp_path)
