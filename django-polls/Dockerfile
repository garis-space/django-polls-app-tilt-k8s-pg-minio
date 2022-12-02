### Build and install packages
FROM python:3.9 as build-python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

### Final image
FROM python:3.9-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Add user and group for the app
RUN groupadd -r app && useradd -r -g app app

WORKDIR /app
COPY --from=build-python /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=build-python /usr/local/bin /usr/local/bin
COPY . .

# Set permissions
RUN chown -R app:app /app
RUN chmod +x /app/entrypoint.sh

# Set permissions for app dir when using this in Tilt
RUN chmod -R 755 /app

# Run as non-root user
USER app

# Run the app
EXPOSE 8000/tcp
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["server"]
