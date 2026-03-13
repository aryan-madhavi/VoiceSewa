FROM node:18

RUN apt-get update && apt-get install -y ffmpeg

WORKDIR /app

COPY package.json .
RUN npm install

COPY index.js .

CMD ["node", "index.js"]
