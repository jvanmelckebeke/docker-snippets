# Docker Snippets

A list of Dockerfile snippets which I frequently use in my docker builds.

## python-libs.Dockerfile

This Dockerfile sets up a Python environment with a minimal amount of pip overhead.
It uses a multistaged build process to

1. create wheels from the requirements,
2. install them into a virtual environment, which is stripped of all unnecessary files,
3. and then copy the virtual environment into a minimal image.

## build-ffmpeg.Dockerfile

This Dockerfile sets up an FFmpeg environment in a multistaged Docker build.
It allows you to configure FFmpeg yourself.
It builds FFmpeg from source and then copies the binary into a minimal image.

## Usage

just copy and paste the relevant Dockerfile parts into your own docker build