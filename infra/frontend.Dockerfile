#STAGE 1: base image with needed installs.
FROM python:3.10.13-slim-bookworm as base

RUN mkdir -p /app/webapp/frontend

WORKDIR /app/webapp/frontend
ADD ./frontend/requirements.txt /app/webapp/frontend/requirements.txt
RUN pip install -r requirements.txt



EXPOSE 8501

# Define environment variable (Streamlit uses this)
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

#STAGE 2: Multi-stage for development with extra installs (e.g. git)
FROM base as dev
RUN apt-get -y update
RUN apt-get -y install git
CMD echo development environment && echo sleeping infinity... ZzzZzzzZZz && sleep infinity

#STAGE 3: Multi-stage for production
FROM base as prod

COPY ./frontend /app/webapp/frontend
COPY ./models /app/webapp/models
COPY ./utils /app/webapp/utils
COPY ./configuration /app/webapp/configuration

WORKDIR /app
CMD echo production-environment && python -m streamlit run webapp/frontend/main.py
