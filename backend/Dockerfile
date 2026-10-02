FROM python:3.12-slim AS builder
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.12-slim
RUN useradd --create-home catalogo
COPY --from=builder /root/.local /home/catalogo/.local
COPY . .
ENV PATH="/home/catalogo/.local/bin:${PATH}" \
    PYTHONUNBUFFERED=1
USER catalogo
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]