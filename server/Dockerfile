FROM node:15.7.0-slim
RUN apt-get update && apt-get install -y python g++ make
RUN mkdir /src
WORKDIR /src
COPY package.json ./
RUN yarn && yarn cache clean
COPY . .
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/debconf/*
