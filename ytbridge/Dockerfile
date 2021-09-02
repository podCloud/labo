FROM node:16-alpine as runner
RUN npm install -g npm

WORKDIR /usr/app

RUN apk add --no-cache ffmpeg

ENV HOME=/usr/app

EXPOSE 3000

CMD [ "npm", "start" ]

FROM runner as ytbridge

COPY package*.json ./

RUN npm install --ci

COPY . .
