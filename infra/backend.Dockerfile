################################
# BUILDER-BASE
# Used to build deps + create our virtual environment
################################
FROM python:3.10.13-slim-bullseye as builder-base

ENV PYTHONUNBUFFERED=1 \
    # prevents python creating .pyc files
    PYTHONDONTWRITEBYTECODE=1 \
    \
    # pip
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    \
    # poetry
    # https://python-poetry.org/docs/configuration/#using-environment-variables
    POETRY_VERSION=1.7.1 \
    # make poetry install to this location
    POETRY_HOME="/opt/poetry" \
    # do not ask any interactive question
    POETRY_NO_INTERACTION=1 \
    \
    # paths
    # this is where our requirements + virtual environment will live
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv" 
    


# prepend poetry and venv to path
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"


RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        # deps for installing poetry
        curl \
        # deps for building python deps
        build-essential

# install poetry - respects $POETRY_VERSION & $POETRY_HOME
RUN curl -sSL https://install.python-poetry.org | python3 -

# copy project requirement files here to ensure they will be cached.
WORKDIR $PYSETUP_PATH
COPY ./backend/poetry.lock ./backend/pyproject.toml ./
# To prevent that there will be a .venv created in the project. Needed when additional libraries are installed.
RUN poetry config virtualenvs.create false
# install production dependencies only. No development dependencies are installed.
RUN poetry install --no-dev

EXPOSE 8000


################################
# DEVELOPMENT
# Image used during development / testing
################################
FROM builder-base as dev
ENV FASTAPI_ENV=dev

# Quicker install as runtime deps are already installed
WORKDIR $PYSETUP_PATH
RUN poetry install  

CMD echo development environment && echo sleeping infinity... ZzzZzzzZZz && sleep infinity


################################
# PRODUCTION
# Final image used for runtime
################################
FROM builder-base as prod

#Production just needs the backend code 
RUN mkdir -p /app/webapp/backend

COPY ../backend /app/webapp/backend

WORKDIR /app
# Using same command as can be used in debugging as the starting directory is the one that contains webapp
CMD echo production-environment && uvicorn webapp.backend.main:app --host 0.0.0.0 --port 8000

