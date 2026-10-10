#####################
#    Build stage    #
#####################
FROM python:3.12@sha256:63828510c8b5ccce3bf0d6fabd6f3d17d4effa1ffe690f80a67c8e2d394e03ee AS build

# Set build environment variables.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set working directory to app.   
WORKDIR /app

# Update package lists, install compilers and cleanup cache.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create an isolated virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy dependencies to current working directory
COPY ./app/requirements.txt .

# Install dependencies without cache
RUN pip install --no-cache-dir -r requirements.txt


##########################
#     Deploy stage       #
##########################
FROM python:3.12@sha256:63828510c8b5ccce3bf0d6fabd6f3d17d4effa1ffe690f80a67c8e2d394e03ee

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    PORT="8080"

# Create user and group: appuser
RUN useradd --system --user-group --shell /usr/sbin/nologin appuser

# Set working directory to app
WORKDIR /app

# Copy compiled package from build stage to virtual environment in deploy stage
COPY --from=build /opt/venv /opt/venv

# Change file ownership to appuser 
# Copy the local app directory to app directory in container current working directory
COPY --chown=appuser:appuser ./app ./app

# Switch from root to appuser
USER appuser

# Application port
EXPOSE ${PORT}

# The whole context was copied to /app, so the app package lives in /app/app.
CMD ["gunicorn", "--chdir", "app", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
