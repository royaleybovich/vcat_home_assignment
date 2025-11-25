# =========================
# Builder image
# =========================
FROM python:3.11-alpine AS build

WORKDIR /app

# System deps (if needed later, keep minimal)
RUN apk add --no-cache build-base

COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

COPY . .

# =========================
# Runtime image
# =========================
FROM python:3.11-alpine

# Create non-root user
RUN addgroup -S app && adduser -S app -G app
USER app

WORKDIR /app

# Copy installed packages from builder
COPY --from=build /install /usr/local
COPY --from=build /app /app

ENV PYTHONUNBUFFERED=1
ENV PORT=3000
ENV APP_ENV=production

EXPOSE 3000

CMD ["gunicorn", "--bind", "0.0.0.0:3000", "server:app"]