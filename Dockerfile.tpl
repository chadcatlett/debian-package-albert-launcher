FROM ubuntu:UBUNTU_VERSION

RUN apt-get update \
  && apt-get install -y git-core build-essential gcc g++ \
  && apt-get install -qq gettext-base \
  && apt-get install -qq cmake qtbase5-dev libqt5x11extras5-dev libqt5svg5-dev libmuparser-dev git-core \
  && rm -rf /var/lib/apt/lists/*
