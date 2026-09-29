FROM python:3.12-slim AS builder
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.12-slim
RUN useradd --create-home --user-group catalogo
WORKDIR /app
COPY --chown=catalogo:catalogo --from=builder /root/.local /home/catalogo/.local
COPY --chown=catalogo:catalogo main.py .
ENV PATH="/home/catalogo/.local/bin:${PATH}"
ENV PYTHONUNBUFFERED=1
ARG APP_VERSION=v1
ENV APP_VERSION=${APP_VERSION}
USER catalogo
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]