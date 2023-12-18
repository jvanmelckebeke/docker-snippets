# use this if you want to setup a multi-staged docker build with a minimal amount of pip overhead

ARG PYTHON_VERSION=3.10.0
ARG PYTHON_BUILD_DISTRO=alpine
# if you use debian in the build distro, then use slim-<debian version> here
ARG PYTHON_MINIMAL_DISTRO=alpine

# step 1: build wheels
FROM python:${PYTHON_VERSION}-${PYTHON_BUILD_DISTRO} as requirements

ENV XDG_CACHE_HOME=/cache

RUN pip install --upgrade pip wheel setuptools

WORKDIR /reqs

COPY ./requirements.txt .

RUN --mount=type=cache,target=/wheels \
    --mount=type=cache,target=/cache \
    pip wheel --wheel-dir=/wheels -r requirements.txt


# step 2: install wheels into a venv, remove unnecessary files
FROM python:${PYTHON_VERSION}-${PYTHON_BUILD_DISTRO} as python-libs

ENV XDG_CACHE_HOME=/cache

RUN pip install --upgrade pip wheel setuptools

RUN python -m venv /venv

ENV PATH=/venv/bin:$PATH


COPY --from=requirements /wheels /wheels
COPY --from=requirements /reqs/requirements.txt /reqs/requirements.txt

RUN --mount=type=cache,target=/wheels \
    --mount=type=cache,target=/cache \
    pip install --no-index --find-links=/wheels -r /reqs/requirements.txt

WORKDIR /venv

# remove pycache
RUN find . -name '__pycache__' -type d -exec rm -rf {} +

# remove tests
RUN find . -name 'tests' -type d -exec rm -rf {} +

# remove precompiled python files
RUN find . -name '*.pyc' -delete && \
    find . -name '*.pyo' -delete && \
    find . -name '*~' -delete

# remove pip and ensurepip, as we don't need them in production
RUN find . -name 'ensurepip' -type d -exec rm -rf {} +
RUN find . -name 'pip' -type d -exec rm -rf {} +

RUN find . -name '*.dist-info' -type d -exec rm -rf {} +


# step 3: copy the venv into a minimal image
FROM python:${PYTHON_VERSION}-${PYTHON_MINIMAL_DISTRO} as runtime

# this is where the magic happens
COPY --from=python-libs /venv/lib/python3.10/site-packages /usr/local/lib/python${PYTHON_VERSION}/dist-packages

WORKDIR /app

COPY ./app.py .

CMD ["python", "app.py"]