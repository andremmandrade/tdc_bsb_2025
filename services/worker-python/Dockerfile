FROM python:3.11-slim AS build
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PYTHONPATH=/app
COPY requirements.txt requirements.txt
COPY requirements-dev.txt requirements-dev.txt
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY app ./app
COPY tests ./tests
# Run unit tests; fail build if they fail
RUN pytest -q

FROM python:3.11-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PYTHONPATH=/app PORT=8000
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
EXPOSE 8000
CMD ["python", "-m", "app.main"]