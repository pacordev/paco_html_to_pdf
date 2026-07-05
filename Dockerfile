FROM python:3.12-slim-bookworm

ARG TARGETARCH
ARG WKHTMLTOX_VERSION=0.12.6.1-3

# wkhtmltopdf was dropped from Debian's own repos, so grab the official
# .deb release directly (built for bookworm) for whichever arch we're
# building on.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        fontconfig \
        libfreetype6 \
        libjpeg62-turbo \
        libpng16-16 \
        libx11-6 \
        libxcb1 \
        libxext6 \
        libxrender1 \
        xfonts-75dpi \
        xfonts-base \
    && case "${TARGETARCH}" in \
         amd64) WKHTMLTOX_ARCH=amd64 ;; \
         arm64) WKHTMLTOX_ARCH=arm64 ;; \
         *) echo "Unsupported architecture: ${TARGETARCH}" >&2 && exit 1 ;; \
       esac \
    && wget -q "https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOX_VERSION}/wkhtmltox_${WKHTMLTOX_VERSION}.bookworm_${WKHTMLTOX_ARCH}.deb" -O /tmp/wkhtmltox.deb \
    && apt-get install -y --no-install-recommends /tmp/wkhtmltox.deb \
    && rm -rf /tmp/wkhtmltox.deb /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ app/
COPY templates/ templates/

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
