ARG build_for=linux/amd64
FROM --platform=$build_for python:3.10.7-slim-bullseye as base

ARG dbt_snowflake_ref=dbt-snowflake
# System setup
RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
    git \
    ssh-client \
    software-properties-common \
    make \
    build-essential \
    ca-certificates \
    libpq-dev \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8

RUN python -m pip install --upgrade pip setuptools wheel --no-cache-dir
WORKDIR /usr/app/dbt/

FROM base as dbt-snowflake
RUN python -m pip install --no-cache-dir "git+https://github.com/dbt-labs/${dbt_snowflake_ref}#egg=dbt-snowflake"

# Create directory for dbt config
RUN mkdir -p /root/.dbt

# Copy dbt profile
COPY profiles.yml /root/.dbt/profiles.yml

# Copy source code
COPY . /usr/app/dbt/

ENTRYPOINT ["python","execute_dbt.py"]